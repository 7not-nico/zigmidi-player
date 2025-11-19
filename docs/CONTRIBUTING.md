# Contributing Guide

## Welcome Contributors! 🎉

Thank you for your interest in contributing to the MIDI Player project. This guide provides comprehensive information for contributors of all experience levels.

## Ways to Contribute

### 🐛 **Bug Reports**
Found a bug? Help us improve by reporting it!

1. **Check existing issues** - Search [GitHub Issues](../../issues) first
2. **Create a new issue** with:
   - Clear title describing the problem
   - Steps to reproduce
   - Expected vs actual behavior
   - System information (OS, Zig version, etc.)
   - Error messages and logs

### 💡 **Feature Requests**
Have an idea for improvement?

1. **Check existing discussions** - Search [GitHub Discussions](../../discussions)
2. **Start a discussion** with:
   - Clear description of the proposed feature
   - Use case and benefits
   - Implementation ideas (optional)

### 🛠️ **Code Contributions**
Ready to write code?

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/your-feature-name`
3. **Make your changes** following our guidelines
4. **Test thoroughly**
5. **Submit a pull request**

## Development Setup

### Prerequisites

- **Zig**: Version 0.15+ ([download](https://ziglang.org/download/))
- **System dependencies**:
  ```bash
  # Ubuntu/Debian
  sudo apt install libfluidsynth-dev libasound2-dev

  # Arch Linux
  sudo pacman -S fluidsynth alsa-lib

  # Fedora
  sudo dnf install fluidsynth-devel alsa-lib-devel
  ```

### Getting Started

```bash
# Clone your fork
git clone https://github.com/your-username/midi_player.git
cd midi_player

# Build and test
zig build
./midi_player --  # List MIDI files
./midi_player demo.mid  # Test playback
```

## Development Workflow

### 1. Choose an Issue

- Look for issues labeled `good first issue` or `help wanted`
- Comment on the issue to indicate you're working on it
- Ask questions if the requirements are unclear

### 2. Create a Branch

```bash
# Create and switch to feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/issue-number-description
```

### 3. Make Changes

Follow our [code style guidelines](../AGENTS.md):

- Use `zig fmt` for consistent formatting
- Write clear commit messages
- Add tests for new functionality
- Update documentation

### 4. Test Your Changes

```bash
# Build
zig build

# Run tests (when available)
zig build test

# Manual testing
./midi_player --                    # List files
./midi_player demo.mid             # Test playback
./midi_player demo.mid soundfonts/standard-midisf.sf2  # Test SoundFont
```

### 5. Commit and Push

```bash
# Stage your changes
git add .

# Commit with clear message
git commit -m "feat: add new feature description

- What was changed
- Why it was changed
- Any breaking changes"

# Push to your fork
git push origin feature/your-feature-name
```

### 6. Create Pull Request

1. Go to the original repository
2. Click "New Pull Request"
3. Select your branch
4. Fill out the PR template:
   - Clear title
   - Description of changes
   - Screenshots/videos if UI changes
   - Link to related issues

## Code Guidelines

### Zig Best Practices

- **Explicit error handling**: Use `!T` and `try`/`catch`
- **RAII pattern**: Use `defer` for resource cleanup
- **Memory management**: Choose appropriate allocators
- **Documentation**: Document public functions with `//!` and `///`

### Naming Conventions

- **Functions**: `camelCase` (`printUsage`, `loadPlaylist`)
- **Structs**: `PascalCase` (`MidiPlayer`, `PlayerState`)
- **Variables**: `snake_case` (`midi_path`, `current_index`)
- **Constants**: `SCREAMING_SNAKE_CASE` (`DEFAULT_VOLUME`)

### Commit Message Format

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Testing
- `chore`: Maintenance

**Examples:**
```
feat: add volume control with +/- keys

- Add adjustVolume() method
- Handle +/= and -/_ keys in main loop
- Update UI to show volume level

Closes #123
```

```
fix: handle missing SoundFont gracefully

Previously crashed when SoundFont not found.
Now shows error message and continues with default.
```

## Testing

### Manual Testing Checklist

Before submitting a PR, test:

- [ ] Code compiles without warnings
- [ ] Basic functionality works (`./midi_player demo.mid`)
- [ ] List command works (`./midi_player --`)
- [ ] All keyboard controls work
- [ ] Error cases handled gracefully
- [ ] No regressions in existing features

### Edge Cases to Test

- Empty MIDI directory
- Corrupted MIDI files
- Missing SoundFont
- Terminal resize during playback
- Rapid key presses
- Very long playlists

## Documentation

### When to Update Docs

- **New features**: Add to relevant guides
- **API changes**: Update API documentation
- **Breaking changes**: Update migration notes
- **Bug fixes**: Update troubleshooting if relevant

### Documentation Files

- **[API.md](API.md)**: Update for new public functions
- **[EXAMPLES.md](EXAMPLES.md)**: Add usage examples
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)**: Add common issues
- **[CHANGELOG.md](../CHANGELOG.md)**: Document changes

## Pull Request Process

### PR Requirements

- [ ] **Title**: Clear, descriptive title
- [ ] **Description**: What and why
- [ ] **Testing**: How to test the changes
- [ ] **Screenshots**: For UI changes
- [ ] **Breaking changes**: Clearly marked
- [ ] **Related issues**: Linked with `Closes #123`

### Review Process

1. **Automated checks**: CI/CD pipeline runs
2. **Code review**: Maintainers review code
3. **Testing**: Reviewers test functionality
4. **Feedback**: Address review comments
5. **Approval**: PR approved and merged

### PR Template

```markdown
## Description
Brief description of the changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
How to test the changes

## Screenshots
If applicable

## Checklist
- [ ] Code compiles
- [ ] Tests pass
- [ ] Documentation updated
- [ ] No breaking changes
```

## Community Guidelines

### Communication

- **Be respectful**: Treat everyone with kindness
- **Be constructive**: Focus on solutions, not problems
- **Ask questions**: Don't assume knowledge
- **Help others**: Share your knowledge

### Issue Reporting

- **Use issue templates**: They help us help you
- **Provide context**: Include relevant information
- **Be specific**: Clear steps to reproduce
- **One issue per report**: Keep things focused

### Code of Conduct

This project follows a code of conduct to ensure a welcoming environment:

- **Inclusivity**: Welcome people from all backgrounds
- **Respect**: Treat others as you wish to be treated
- **Collaboration**: Work together constructively
- **Professionalism**: Keep discussions appropriate

## Getting Help

### Resources

- **[README.md](../README.md)**: Main project documentation
- **[Developer Guide](DEVELOPER.md)**: Development setup and workflow
- **[API Reference](API.md)**: Technical API documentation
- **[Troubleshooting](TROUBLESHOOTING.md)**: Common issues and solutions

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and ideas
- **Pull Request Comments**: Code review discussions

### When to Ask for Help

- Unclear requirements or implementation approach
- Stuck on technical issues
- Need design feedback
- Want to discuss architectural decisions

## Recognition

Contributors are recognized through:

- **GitHub contributor statistics**
- **Changelog entries**
- **Mention in release notes**
- **Community recognition**

Thank you for contributing to the MIDI Player project! Your efforts help make MIDI playback better for everyone. 🎵