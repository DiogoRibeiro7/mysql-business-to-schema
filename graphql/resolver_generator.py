#!/usr/bin/env python3
"""
GraphQL Resolver Generator for Apollo Server

Generates TypeScript/JavaScript resolver templates with:
- DataLoader integration for N+1 query prevention
- Database query builders
- Error handling
- Authentication/Authorization hooks
- Caching strategies
"""

import json
from pathlib import Path
from typing import Dict, List, Optional
from datetime import datetime

class ResolverGenerator:
    """Generate resolver templates for GraphQL schemas"""

    def __init__(self, schema_info: Dict):
        self.schema_info = schema_info
        self.tables = schema_info.get('tables', {})

    def generate_resolvers_ts(self) -> str:
        """Generate TypeScript resolvers with full type safety"""
        parts = []

        # Imports
        parts.append(self._generate_imports())

        # DataLoader factories
        parts.append(self._generate_dataloaders())

        # Resolver implementations
        parts.append(self._generate_query_resolvers())
        parts.append(self._generate_mutation_resolvers())
        parts.append(self._generate_subscription_resolvers())
        parts.append(self._generate_field_resolvers())

        # Export resolver map
        parts.append(self._generate_resolver_map())

        return '\n\n'.join(parts)

    def _generate_imports(self) -> str:
        """Generate import statements"""
        return """import { GraphQLResolveInfo } from 'graphql';
import { PubSub } from 'graphql-subscriptions';
import DataLoader from 'dataloader';
import {
  Context,
  DatabaseConnection,
  PaginationArgs,
  FilterInput,
  SortInput
} from '../types';
import {
  AuthenticationError,
  UserInputError,
  ForbiddenError,
  ApolloError
} from 'apollo-server-express';
import {
  buildQuery,
  applyFilters,
  applySorting,
  applyPagination,
  encodeCursor,
  decodeCursor
} from '../utils/query-builder';
import {
  checkPermission,
  requireAuth,
  rateLimit
} from '../utils/auth';
import { cache } from '../utils/cache';
import { logger } from '../utils/logger';

const pubsub = new PubSub();"""

    def _generate_dataloaders(self) -> str:
        """Generate DataLoader factories for preventing N+1 queries"""
        loaders = []

        for table_name, table_info in self.tables.items():
            type_name = self._to_pascal_case(table_name)

            loaders.append(f"""// DataLoader for {type_name}
export function create{type_name}Loader(db: DatabaseConnection): DataLoader<string, {type_name}> {{
  return new DataLoader(async (ids: readonly string[]) => {{
    const query = `
      SELECT * FROM {table_name}
      WHERE id IN (${{ids.map(() => '?').join(', ')}})
    `;

    const rows = await db.query(query, [...ids]);

    // Create a map for O(1) lookups
    const rowMap = new Map(rows.map(row => [row.id, row]));

    // Return in the same order as requested
    return ids.map(id => rowMap.get(id) || null);
  }}, {{
    cacheKeyFn: (key) => `{table_name}:${{key}}`,
    maxBatchSize: 100,
  }});
}}""")

            # Add relationship loaders
            for fk in table_info.get('foreign_keys', []):
                ref_table = fk['ref_table']
                ref_type = self._to_pascal_case(ref_table)

                loaders.append(f"""// DataLoader for {type_name} -> {ref_type} relationship
export function create{type_name}{ref_type}Loader(db: DatabaseConnection): DataLoader<string, {ref_type}[]> {{
  return new DataLoader(async (parentIds: readonly string[]) => {{
    const query = `
      SELECT * FROM {ref_table}
      WHERE {fk['column']} IN (${{parentIds.map(() => '?').join(', ')}})
    `;

    const rows = await db.query(query, [...parentIds]);

    // Group by parent ID
    const grouped = new Map<string, {ref_type}[]>();
    for (const row of rows) {{
      const parentId = row.{fk['column']};
      if (!grouped.has(parentId)) {{
        grouped.set(parentId, []);
      }}
      grouped.get(parentId)!.push(row);
    }}

    // Return in order with empty arrays for missing
    return parentIds.map(id => grouped.get(id) || []);
  }});
}}""")

        return f"""// DataLoader Factories
{chr(10).join(loaders)}

// Create all loaders for context
export function createLoaders(db: DatabaseConnection) {{
  return {{
    {chr(10).join([f"{self._to_camel_case(name)}: create{self._to_pascal_case(name)}Loader(db)," for name in self.tables.keys()])}
  }};
}}"""

    def _generate_query_resolvers(self) -> str:
        """Generate Query resolvers"""
        resolvers = []

        for table_name, table_info in self.tables.items():
            type_name = self._to_pascal_case(table_name)
            singular = self._to_camel_case(table_name)
            plural = self._to_plural(singular)

            # Single item query
            resolvers.append(f"""  {singular}: async (
    _: any,
    {{ id }}: {{ id: string }},
    {{ db, loaders, user }}: Context
  ): Promise<{type_name} | null> => {{
    try {{
      // Check permissions
      await checkPermission(user, 'read', '{table_name}');

      // Use DataLoader for caching
      return await loaders.{singular}.load(id);
    }} catch (error) {{
      logger.error('Error fetching {singular}:', error);
      throw new ApolloError('Failed to fetch {singular}');
    }}
  }},""")

            # List query with pagination
            resolvers.append(f"""  {plural}: async (
    _: any,
    args: PaginationArgs & {{ filter?: FilterInput, sort?: SortInput[] }},
    {{ db, user }}: Context
  ): Promise<{type_name}Connection> => {{
    try {{
      // Check permissions
      await checkPermission(user, 'read', '{table_name}');

      // Build base query
      let query = db.select().from('{table_name}');

      // Apply filters
      if (args.filter) {{
        query = applyFilters(query, args.filter);
      }}

      // Apply sorting
      if (args.sort) {{
        query = applySorting(query, args.sort);
      }}

      // Get total count for pagination info
      const countQuery = query.clone();
      const totalCount = await countQuery.count();

      // Apply pagination
      const {{ limit, offset, cursor }} = decodeCursor(args);
      query = query.limit(limit + 1).offset(offset);

      // Execute query
      const rows = await query.execute();

      // Check if there's a next page
      const hasNextPage = rows.length > limit;
      if (hasNextPage) {{
        rows.pop(); // Remove the extra row
      }}

      // Build connection response
      const edges = rows.map((node, index) => ({{
        node,
        cursor: encodeCursor({{ offset: offset + index }}),
      }}));

      return {{
        edges,
        pageInfo: {{
          hasNextPage,
          hasPreviousPage: offset > 0,
          startCursor: edges[0]?.cursor,
          endCursor: edges[edges.length - 1]?.cursor,
          total: totalCount,
        }},
      }};
    }} catch (error) {{
      logger.error('Error fetching {plural}:', error);
      throw new ApolloError('Failed to fetch {plural}');
    }}
  }},""")

            # Search query
            resolvers.append(f"""  search{type_name}: async (
    _: any,
    {{ query }}: {{ query: string }},
    {{ db, user }}: Context
  ): Promise<{type_name}[]> => {{
    try {{
      // Check permissions
      await checkPermission(user, 'read', '{table_name}');

      // Build full-text search query
      const searchQuery = `
        SELECT * FROM {table_name}
        WHERE MATCH(searchable_columns) AGAINST(? IN NATURAL LANGUAGE MODE)
        LIMIT 50
      `;

      const results = await db.query(searchQuery, [query]);

      // Cache results for 5 minutes
      await cache.set(`search:{table_name}:${{query}}`, results, 300);

      return results;
    }} catch (error) {{
      logger.error('Error searching {table_name}:', error);
      throw new ApolloError('Search failed');
    }}
  }},""")

        return f"""// Query Resolvers
const Query = {{
{chr(10).join(resolvers)}

  // Health check
  health: async (): Promise<string> => {{
    return 'OK';
  }},

  // Node interface implementation
  node: async (
    _: any,
    {{ id }}: {{ id: string }},
    context: Context
  ): Promise<any | null> => {{
    // Parse the global ID to get type and local ID
    const [type, localId] = Buffer.from(id, 'base64').toString().split(':');

    // Route to appropriate loader based on type
    const loader = context.loaders[type];
    if (!loader) {{
      throw new UserInputError(`Unknown type: ${{type}}`);
    }}

    return await loader.load(localId);
  }},
}};"""

    def _generate_mutation_resolvers(self) -> str:
        """Generate Mutation resolvers"""
        resolvers = []

        for table_name, table_info in self.tables.items():
            type_name = self._to_pascal_case(table_name)
            singular = self._to_camel_case(table_name)

            # Create mutation
            resolvers.append(f"""  create{type_name}: async (
    _: any,
    {{ input }}: {{ input: Create{type_name}Input }},
    {{ db, user }}: Context
  ): Promise<{type_name}> => {{
    try {{
      // Require authentication
      requireAuth(user);

      // Check permissions
      await checkPermission(user, 'create', '{table_name}');

      // Validate input
      await validate{type_name}Input(input);

      // Start transaction
      const trx = await db.transaction();

      try {{
        // Insert record
        const [id] = await trx('{table_name}').insert({{
          ...input,
          created_at: new Date(),
          updated_at: new Date(),
          created_by: user.id,
        }});

        // Fetch the created record
        const created = await trx('{table_name}').where({{ id }}).first();

        // Commit transaction
        await trx.commit();

        // Publish subscription event
        await pubsub.publish('{singular.toUpperCase()}_CREATED', {{
          {singular}Created: created,
        }});

        // Clear relevant caches
        await cache.del(`{table_name}:list:*`);

        return created;
      }} catch (error) {{
        await trx.rollback();
        throw error;
      }}
    }} catch (error) {{
      logger.error('Error creating {singular}:', error);
      throw new ApolloError('Failed to create {singular}');
    }}
  }},""")

            # Update mutation
            resolvers.append(f"""  update{type_name}: async (
    _: any,
    {{ id, input }}: {{ id: string, input: Update{type_name}Input }},
    {{ db, user, loaders }}: Context
  ): Promise<{type_name}> => {{
    try {{
      // Require authentication
      requireAuth(user);

      // Check if record exists
      const existing = await loaders.{singular}.load(id);
      if (!existing) {{
        throw new UserInputError('{type_name} not found');
      }}

      // Check permissions
      await checkPermission(user, 'update', '{table_name}', existing);

      // Validate input
      await validate{type_name}Input(input, true);

      // Update record
      await db('{table_name}').where({{ id }}).update({{
        ...input,
        updated_at: new Date(),
        updated_by: user.id,
      }});

      // Clear from DataLoader cache
      loaders.{singular}.clear(id);

      // Fetch updated record
      const updated = await loaders.{singular}.load(id);

      // Publish subscription event
      await pubsub.publish('{singular.toUpperCase()}_UPDATED', {{
        {singular}Updated: updated,
      }});

      // Clear relevant caches
      await cache.del(`{table_name}:${{id}}`);
      await cache.del(`{table_name}:list:*`);

      return updated;
    }} catch (error) {{
      logger.error('Error updating {singular}:', error);
      throw new ApolloError('Failed to update {singular}');
    }}
  }},""")

            # Delete mutation
            resolvers.append(f"""  delete{type_name}: async (
    _: any,
    {{ id }}: {{ id: string }},
    {{ db, user, loaders }}: Context
  ): Promise<OperationResult> => {{
    try {{
      // Require authentication
      requireAuth(user);

      // Check if record exists
      const existing = await loaders.{singular}.load(id);
      if (!existing) {{
        throw new UserInputError('{type_name} not found');
      }}

      // Check permissions
      await checkPermission(user, 'delete', '{table_name}', existing);

      // Soft delete or hard delete based on configuration
      if (process.env.SOFT_DELETE === 'true') {{
        await db('{table_name}').where({{ id }}).update({{
          deleted_at: new Date(),
          deleted_by: user.id,
        }});
      }} else {{
        await db('{table_name}').where({{ id }}).delete();
      }}

      // Clear from DataLoader cache
      loaders.{singular}.clear(id);

      // Publish subscription event
      await pubsub.publish('{singular.toUpperCase()}_DELETED', {{ id }});

      // Clear caches
      await cache.del(`{table_name}:${{id}}`);
      await cache.del(`{table_name}:list:*`);

      return {{
        success: true,
        message: '{type_name} deleted successfully',
      }};
    }} catch (error) {{
      logger.error('Error deleting {singular}:', error);
      throw new ApolloError('Failed to delete {singular}');
    }}
  }},""")

        return f"""// Mutation Resolvers
const Mutation = {{
{chr(10).join(resolvers)}
}};"""

    def _generate_subscription_resolvers(self) -> str:
        """Generate Subscription resolvers"""
        resolvers = []

        for table_name in self.tables.keys():
            type_name = self._to_pascal_case(table_name)
            singular = self._to_camel_case(table_name)

            resolvers.append(f"""  {singular}Created: {{
    subscribe: withFilter(
      () => pubsub.asyncIterator('{singular.upper()}_CREATED'),
      (payload, variables, context) => {{
        // Filter based on user permissions
        return checkPermission(context.user, 'read', '{table_name}', payload.{singular}Created);
      }}
    ),
  }},

  {singular}Updated: {{
    subscribe: withFilter(
      () => pubsub.asyncIterator('{singular.upper()}_UPDATED'),
      (payload, variables, context) => {{
        // Filter based on ID and permissions
        return payload.{singular}Updated.id === variables.id &&
               checkPermission(context.user, 'read', '{table_name}', payload.{singular}Updated);
      }}
    ),
  }},

  {singular}Deleted: {{
    subscribe: () => pubsub.asyncIterator('{singular.upper()}_DELETED'),
  }},""")

        return f"""// Subscription Resolvers
import {{ withFilter }} from 'graphql-subscriptions';

const Subscription = {{
{chr(10).join(resolvers)}
}};"""

    def _generate_field_resolvers(self) -> str:
        """Generate field resolvers for relationships"""
        resolvers = []

        for table_name, table_info in self.tables.items():
            type_name = self._to_pascal_case(table_name)
            field_resolvers = []

            # Add relationship resolvers
            for fk in table_info.get('foreign_keys', []):
                ref_table = fk['ref_table']
                ref_type = self._to_pascal_case(ref_table)
                ref_field = self._to_camel_case(ref_table)

                field_resolvers.append(f"""  {ref_field}: async (
    parent: {type_name},
    _: any,
    {{ loaders }}: Context
  ): Promise<{ref_type} | null> => {{
    if (!parent.{fk['column']}) return null;
    return await loaders.{ref_field}.load(parent.{fk['column']});
  }},""")

            if field_resolvers:
                resolvers.append(f"""// {type_name} field resolvers
const {type_name} = {{
{chr(10).join(field_resolvers)}
}};""")

        return '\n\n'.join(resolvers)

    def _generate_resolver_map(self) -> str:
        """Generate the main resolver map export"""
        type_resolvers = [self._to_pascal_case(name) for name in self.tables.keys()]

        return f"""// Export resolver map
export const resolvers = {{
  Query,
  Mutation,
  Subscription,
  {chr(10).join([f'  {name},' for name in type_resolvers if name in type_resolvers])}

  // Custom scalars
  DateTime: DateTimeResolver,
  Date: DateResolver,
  Time: TimeResolver,
  JSON: JSONResolver,
  BigInt: BigIntResolver,
  Decimal: DecimalResolver,
}};

// Validation functions
{self._generate_validation_functions()}

// Helper functions
function withFilter(
  asyncIteratorFn: Function,
  filterFn: Function
): any {{
  // Implementation of withFilter for subscriptions
  return {{
    subscribe: async (parent: any, args: any, context: any, info: any) => {{
      const asyncIterator = await asyncIteratorFn(parent, args, context, info);
      const filterIterator = {{
        async next() {{
          let value;
          do {{
            value = await asyncIterator.next();
            if (value.done) return value;
          }} while (!await filterFn(value.value, args, context, info));
          return value;
        }},
        return() {{
          return asyncIterator.return ? asyncIterator.return() : Promise.resolve({{ done: true, value: undefined }});
        }},
        throw(error: any) {{
          return asyncIterator.throw ? asyncIterator.throw(error) : Promise.reject(error);
        }},
        [Symbol.asyncIterator]() {{
          return this;
        }},
      }};
      return filterIterator;
    }},
  }};
}}"""

    def _generate_validation_functions(self) -> str:
        """Generate input validation functions"""
        validations = []

        for table_name in self.tables.keys():
            type_name = self._to_pascal_case(table_name)

            validations.append(f"""async function validate{type_name}Input(
  input: any,
  isUpdate: boolean = false
): Promise<void> {{
  // Add validation logic based on your business rules
  // Throw UserInputError for validation failures

  // Example validations:
  // - Required fields
  // - Format validation (email, phone, etc.)
  // - Range checks
  // - Uniqueness checks
  // - Business rule validation
}}""")

        return '\n\n'.join(validations)

    def _to_camel_case(self, snake_str: str) -> str:
        """Convert snake_case to camelCase"""
        components = snake_str.split('_')
        return components[0].lower() + ''.join(x.title() for x in components[1:])

    def _to_pascal_case(self, snake_str: str) -> str:
        """Convert snake_case to PascalCase"""
        return ''.join(x.title() for x in snake_str.split('_'))

    def _to_plural(self, word: str) -> str:
        """Convert word to plural"""
        if word.endswith('y'):
            return word[:-1] + 'ies'
        elif word.endswith('s'):
            return word + 'es'
        else:
            return word + 's'

    def export_resolvers(self, output_file: Path):
        """Export resolvers to file"""
        resolvers = self.generate_resolvers_ts()
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(resolvers)
        print(f"Resolvers exported to: {output_file}")
