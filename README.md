# httpz

A meat and potatoes HTTP server written in ZSH, using nc (netcat).

## Usage

### Flags

| flag                                                        | description           |
| ----------------------------------------------------------- | --------------------- |
| `-s` (`--static`),<br> `-h` (`--html`),<br> `-f` (`--file`) | Required server type. |
| `-p` `--port`,                                              | Optional port number. |

## To Do

- [ ] Separate query string, split parameters
- [x] Read response
- [ ] file server
  - [ ] images
    - [x] PNG
    - [ ] JPEG
    - [ ] GIF
  - [ ] JS
  - [ ] CSS
  - list files
  - list directories
  - navigate directories
  - server files
- [x] Use Z shell TCP module

## References

- [zshttpd](https://github.com/alter2000/.dots/blob/master/zsh/bin/zshttpd.zsh)
- [Building a Web server in Bash](https://dev.to/leandronsp/building-a-web-server-in-bash-part-ii-parsing-http-14kg)
