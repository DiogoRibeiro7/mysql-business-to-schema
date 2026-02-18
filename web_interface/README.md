# MySQL Examples Web Interface

A modern web application for browsing and exploring the MySQL Business-to-Schema database examples.

## Features

- 📚 **Browse All Examples**: View all 13 database examples with descriptions and statistics
- 🔍 **Search Functionality**: Search across all schemas, queries, and documentation
- 📊 **Syntax Highlighting**: Beautiful code display with syntax highlighting for SQL, Python, and YAML
- 📁 **File Explorer**: Navigate through schema files, queries, and generator configurations
- 🔄 **Compare Examples**: Side-by-side comparison of multiple examples
- 📥 **Download Schemas**: Download individual schema files or complete examples
- 📱 **Responsive Design**: Works perfectly on desktop, tablet, and mobile devices
- 🎨 **Modern UI**: Clean, professional interface using Bootstrap 5

## Screenshots

### Home Page
- Grid view of all examples organized by category
- Quick statistics and filters
- Search functionality

### Example Detail Page
- Complete README documentation
- Schema files with syntax highlighting
- Query examples
- Data generator configuration
- ER diagram placeholder

### Comparison View
- Compare multiple examples side by side
- Highlight differences and similarities
- Export comparison results

## Installation

### Prerequisites

- Python 3.10 or higher
- Poetry

### Setup

1. Install dependencies (from the repo root):
```bash
poetry install --no-root --with web
```

2. Run the application:
```bash
poetry run python web_interface/app.py
```

4. Open your browser and navigate to:
```
http://localhost:5000
```

## Development

### Project Structure

```
web_interface/
├── app.py                 # Flask application
├── templates/            # HTML templates
│   ├── base.html        # Base template
│   ├── index.html       # Home page
│   ├── example.html     # Example detail page
│   ├── compare.html     # Comparison page
│   ├── search.html      # Search results
│   ├── tools.html       # Tools overview
│   └── documentation.html # Documentation
├── static/              # Static assets
│   ├── css/
│   │   └── style.css   # Custom styles
│   ├── js/
│   │   └── main.js     # JavaScript functionality
│   └── img/            # Images
└── README.md           # This file
```

### Running in Development Mode

```bash
# With debug mode enabled
export FLASK_ENV=development
export FLASK_DEBUG=1
poetry run python web_interface/app.py
```

### Running in Production

For production deployment, use Gunicorn:

```bash
poetry run gunicorn -w 4 -b 0.0.0.0:8000 app:app
```

## Docker Deployment

### Build the Docker image:

```dockerfile
FROM python:3.10-slim

WORKDIR /app

COPY pyproject.toml poetry.lock* ./
RUN pip install --no-cache-dir poetry \
  && poetry config virtualenvs.create false \
  && poetry install --no-root --only main --with web --no-interaction --no-ansi

COPY . .

EXPOSE 5000

CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "app:app"]
```

### Run with Docker:

```bash
docker build -t mysql-examples-web .
docker run -p 5000:5000 mysql-examples-web
```

## API Endpoints

The web interface also provides several API endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/stats` | GET | Get overall statistics |
| `/api/examples` | GET | List all examples |
| `/api/example/<path>` | GET | Get example details |
| `/api/search?q=<query>` | GET | Search examples |

## Features in Detail

### 1. Example Browser
- Filterable by category (IoT, Financial, Social, etc.)
- Quick stats for each example (tables, queries, indexes)
- Direct links to schema and query files
- Generator availability indicator

### 2. Code Viewer
- Syntax highlighting for SQL, Python, and YAML
- Line numbers
- Copy to clipboard functionality
- File navigation sidebar
- Download individual files

### 3. Search System
- Full-text search across all files
- Contextual results display
- Search highlighting
- Filter by file type

### 4. Comparison Tool
- Select multiple examples to compare
- Side-by-side schema comparison
- Highlight structural differences
- Export comparison results

### 5. Documentation Browser
- Markdown rendering with syntax highlighting
- Table of contents generation
- Anchor links for navigation
- Print-friendly formatting

## Customization

### Adding New Examples

The web interface automatically discovers new examples. Simply add your example following the standard structure:

```
example_XX_name/
├── README.md
├── schema/
│   └── *.sql
├── queries/
│   └── *.sql
└── data/
    └── *.sql
```

### Modifying Styles

Edit `static/css/style.css` to customize the appearance. The interface uses CSS variables for easy theming:

```css
:root {
    --primary-color: #0066cc;
    --secondary-color: #6c757d;
    /* ... other variables ... */
}
```

### Adding New Features

1. Add new route in `app.py`
2. Create template in `templates/`
3. Add navigation link in `base.html`
4. Update styles in `style.css`

## Browser Support

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## Performance

- Lazy loading for large files
- Client-side caching
- Minified assets in production
- Gzip compression enabled

## Security

- Input sanitization for search queries
- XSS protection via template escaping
- CORS configured for API endpoints
- No database credentials exposed

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - Same as the main project

## Support

For issues or questions about the web interface:
- Open an issue on GitHub
- Check existing documentation
- Contact the maintainers

## Future Enhancements

- [ ] Live SQL query execution
- [ ] ER diagram generation from schema
- [ ] Export to various formats (PDF, Word)
- [ ] User authentication for private examples
- [ ] Comments and annotations
- [ ] Version comparison
- [ ] Performance metrics dashboard
- [ ] Integration with MySQL Workbench
