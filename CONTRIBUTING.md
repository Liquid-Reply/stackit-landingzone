# Contributing

Thank you for your interest in contributing to the STACKIT Landing Zone project!

## How to Contribute

### Reporting Issues

- Use GitHub Issues to report bugs or request features
- Include as much detail as possible: Terraform version, provider version, error messages, and steps to reproduce

### Submitting Changes

1. Fork the repository
2. Create a feature branch from `main`
3. Make your changes
4. Ensure `terraform fmt` and `terraform validate` pass for all layers
5. Submit a Pull Request with a clear description of the changes

### Code Style

- Run `terraform fmt -recursive` before committing
- Use meaningful variable and resource names
- Add descriptions to all variables and outputs
- Comment complex logic or non-obvious design decisions

### Commit Messages

- Use clear, concise commit messages
- Reference issues where applicable (e.g., `Fixes #42`)

### Module Changes

When modifying shared modules in `modules/`:
- Ensure backward compatibility or clearly document breaking changes
- Update variable descriptions and defaults
- Test changes across all layers that use the module

## Development Setup

### Prerequisites

- Terraform >= 1.7
- A STACKIT account with an organization (for testing)
- STACKIT CLI (optional, for service account management)

### Local Testing

```bash
# Format all files
make fmt

# Validate all layers (does not require credentials)
make validate
```

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.
