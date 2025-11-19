# Security Policy

## Supported Versions

We actively support the following versions with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |
| < 0.1   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in the MIDI Player, please help us by reporting it responsibly.

### How to Report

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report security vulnerabilities by emailing:
- **Email**: [security@midi-player.dev](mailto:security@midi-player.dev) (placeholder - replace with actual contact)

### What to Include

When reporting a security vulnerability, please include:

1. **Description**: A clear description of the vulnerability
2. **Steps to Reproduce**: Detailed steps to reproduce the issue
3. **Impact**: Potential impact and severity of the vulnerability
4. **Environment**: Your system details (OS, Zig version, etc.)
5. **Proof of Concept**: If possible, include a proof of concept

### Response Timeline

We will acknowledge your report within 48 hours and provide a more detailed response within 7 days indicating our next steps.

We will keep you informed about our progress throughout the process of fixing the vulnerability.

### Disclosure Policy

- We follow a coordinated disclosure process
- We will credit you (if desired) in our security advisory
- We will not disclose vulnerability details until a fix is available
- We will provide advance notice of public disclosure

## Security Considerations

### Audio Security

The MIDI Player processes audio data through FluidSynth and ALSA. While we strive for security, audio processing inherently involves:

- **Real-time processing**: May have timing-related security implications
- **External libraries**: Dependencies on FluidSynth and ALSA
- **System audio access**: Requires audio device permissions

### File Handling

- **MIDI files**: Parsed by FluidSynth - ensure files come from trusted sources
- **SoundFont files**: Loaded into memory - validate file integrity
- **Configuration files**: JSON parsing - standard security considerations apply

### Network Security

Currently, the MIDI Player does not include network functionality. Future network features will follow security best practices.

## Security Best Practices

### For Users

1. **Download from trusted sources**: Only download the MIDI Player from official repositories
2. **Verify checksums**: When available, verify download integrity
3. **Use trusted MIDI files**: Only load MIDI files from trusted sources
4. **Regular updates**: Keep the application updated with security patches
5. **Secure configuration**: Protect your `~/.config/midi_player/` directory

### For Developers

1. **Input validation**: Validate all inputs, especially file paths and configuration
2. **Memory safety**: Leverage Zig's memory safety features
3. **Dependency updates**: Keep dependencies (FluidSynth, ALSA) updated
4. **Code review**: All changes undergo security-focused code review
5. **Testing**: Include security testing in the development process

## Known Security Considerations

### Audio Subsystem

- **ALSA permissions**: Requires audio device access
- **Real-time scheduling**: May require special permissions for optimal performance
- **Audio buffer handling**: Potential for audio-related vulnerabilities in dependencies

### File System Access

- **Configuration directory**: Creates `~/.config/midi_player/` with user permissions
- **MIDI file access**: Reads files from `midis/` directory
- **SoundFont loading**: Loads binary SoundFont files into memory

### External Dependencies

- **FluidSynth**: Complex audio synthesis library
- **ALSA**: Linux audio subsystem
- **Zig standard library**: Memory-safe but depends on system libraries

## Security Updates

Security updates will be:

1. **Developed privately**: Security fixes developed without public visibility
2. **Tested thoroughly**: Comprehensive testing before release
3. **Documented**: Security advisories published for significant issues
4. **Released promptly**: Critical security fixes released as soon as possible

## Contact

For security-related questions or concerns:

- **Security Issues**: Use the reporting process above
- **General Questions**: Create a GitHub Discussion
- **Bug Reports**: Use GitHub Issues with appropriate labels

Thank you for helping keep the MIDI Player secure!