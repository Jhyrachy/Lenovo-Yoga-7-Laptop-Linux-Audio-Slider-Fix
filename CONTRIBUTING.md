# Contributing to Lenovo 14IRH8 Audio Fix

Thank you for your interest in contributing! This project helps Linux users fix audio volume control issues on Lenovo laptops and similar devices.

## How to Contribute

### 🐛 Reporting Issues

When reporting issues, please include:

1. **Hardware Information:**
   - Laptop model (e.g., Lenovo 14IRH8, IdeaPad Gaming 3, etc.)
   - Audio chipset if known

2. **Software Environment:**
   - Linux distribution and version
   - Desktop environment (GNOME, KDE, XFCE, etc.)
   - Audio system (PipeWire version, WirePlumber version)

3. **Audio Device Information:**
   ```bash
   # Include output of these commands:
   wpctl status
   wpctl inspect <your-sink-id>
   ```

4. **Error Details:**
   - Exact error messages
   - Script output (if applicable)
   - Steps to reproduce

### ✨ Suggesting Enhancements

- Check existing issues first to avoid duplicates
- Describe the enhancement in detail
- Explain why it would be useful
- Consider backward compatibility

### 🔧 Code Contributions

#### Prerequisites
- Basic knowledge of Bash scripting
- Understanding of Linux audio systems (PipeWire/WirePlumber)
- Ability to test on real hardware

#### Development Setup

1. **Fork the repository**

2. **Clone your fork:**
   ```bash
   git clone https://github.com/your-username/lenovo-14irh8-audio-fix.git
   cd lenovo-14irh8-audio-fix
   ```

3. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Make your changes**

5. **Test thoroughly:**
   - Test the installation process
   - Test the restoration process
   - Test on different audio devices if possible
   - Verify error handling

#### Coding Standards

- **Bash scripting:**
  - Use `set -e` for error handling
  - Quote variables properly: `"$variable"`
  - Use meaningful function and variable names
  - Add comments for complex logic

- **Output formatting:**
  - Use the existing color scheme
  - Maintain consistent formatting
  - Provide clear error messages

- **Safety:**
  - Always create backups before modifying system files
  - Validate user input
  - Provide safe rollback mechanisms

#### Pull Request Process

1. **Update documentation** if needed (README.md, comments)

2. **Test your changes** on actual hardware

3. **Commit with clear messages:**
   ```bash
   git commit -m "Add support for XYZ audio chipset"
   ```

4. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```

5. **Create a Pull Request** with:
   - Clear description of changes
   - Testing information
   - Hardware compatibility notes

### 📖 Documentation Contributions

- Fix typos, grammar, or unclear instructions
- Add information about new compatible hardware
- Improve troubleshooting sections
- Translate documentation (create language-specific README files)

### 🧪 Testing Contributions

Help test the scripts on different hardware:

- Different Lenovo models
- Other laptop brands with similar issues
- Various Linux distributions
- Different audio configurations

**Testing Report Template:**
```markdown
## Hardware
- Model: [Lenovo Model]
- Audio chipset: [if known]

## Software
- OS: [Distribution + Version]
- Desktop: [GNOME/KDE/etc.]
- PipeWire version: [version]

## Test Results
- [ ] Installation script works
- [ ] Audio fix resolves volume issue
- [ ] Restore script works correctly
- [ ] No system instability

## Notes
[Any additional observations]
```

## Review Process

- All contributions will be reviewed for functionality and safety
- Testing on real hardware is preferred when possible
- Documentation changes are usually quick to review
- Code changes may require more thorough testing

## Recognition

Contributors will be:
- Listed in the README credits section
- Mentioned in release notes for significant contributions
- Thanked in commit messages

## Questions?

- Open an issue for questions about contributing
- Check existing issues and discussions
- Be patient and respectful in all interactions

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help newcomers learn
- Acknowledge that this is a community effort

Thank you for helping make Linux audio better for everyone! 🎵
