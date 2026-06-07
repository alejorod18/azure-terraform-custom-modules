# Contributing to Azure Terraform Custom Modules

Thank you for your interest in contributing! Here's how you can help.

## 🐛 Reporting Bugs

Open an issue with:
- Module name affected
- Terraform and AzureRM provider versions
- Steps to reproduce
- Expected vs. actual behavior
- Relevant `terraform plan` or `terraform apply` output

## 💡 Suggesting Enhancements

Open an issue describing:
- The use case or problem
- Your proposed solution
- Which module(s) would be affected

## 🔀 Pull Requests

1. **Fork** the repository
2. **Create a feature branch**: `git checkout -b feature/my-change`
3. **Make your changes** following the conventions below
4. **Test** your changes with `terraform validate` and `terraform plan`
5. **Commit** with clear, descriptive messages
6. **Push** and open a Pull Request

## 📐 Conventions

### File Structure (per module)

```
module-<name>-infrastructure/
├── main.tf              # Primary resource definitions
├── variables.tf         # Input variables with validations
├── outputs.tf           # Output values
├── versions.tf          # Provider and Terraform version constraints
├── data.tf              # Data sources
├── diagnostics.tf       # Log Analytics diagnostic settings (if applicable)
├── private_endpoints.tf # Private endpoint configuration (if applicable)
├── README.md            # Module-specific documentation
├── .gitignore           # Terraform-specific ignores
└── example/
    └── simple/
        ├── main.tf
        ├── providers.tf
        └── outputs.tf
```

### Coding Standards

- Use `snake_case` for all Terraform identifiers
- Include `description` on all variables
- Add `validation` blocks to variables where possible
- Use `locals` to compute derived values
- Set sensible `default` values where applicable
- All string values in English; comments may be in Spanish or English
- Use `lifecycle { prevent_destroy = true }` for production-critical resources

### Documentation

- Each module must have its own `README.md`
- Include at least one working example in the `example/` directory
- Document all input variables, outputs, and resources created

## ✅ Before Submitting

- [ ] `terraform fmt` passes
- [ ] `terraform validate` passes
- [ ] `terraform plan` runs without errors (with mock values)
- [ ] README is updated if variables/outputs changed
- [ ] No sensitive data (passwords, subscription IDs, IPs) in the code

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.
