# httpz

A meat and potatoes HTTP server written in ZSH, using nc (netcat).

## Usage

### Flags

| flag                                                        | description           |
| ----------------------------------------------------------- | --------------------- |
| `-s` (`--static`),<br> `-h` (`--html`),<br> `-f` (`--file`) | Required server type. |
| `-p` `--port`,                                              | Optional port number. |

## To Do

- [ ] Separate query string, split parameters into an associative array
- [x] Read response
- [ ] file server
  - [x] images
    - [x] PNG
    - [x] JPEG
    - [x] GIF
    - [x] WEBP
  - [x] JS
  - [x] CSS
  - [ ] JSON
  - [ ] YAML
  - list files
  - list directories
  - navigate directories
  - server files
- [x] Use Z shell TCP module
- [ ] Support darwin
  - [ ] wc - option differ
  - [ ] file - doesn't specify binary files

## References

- [zshttpd](https://github.com/alter2000/.dots/blob/master/zsh/bin/zshttpd.zsh)
- [Building a Web server in Bash](https://dev.to/leandronsp/building-a-web-server-in-bash-part-ii-parsing-http-14kg)

## Attribution

By NASA/EPIC, edit by <a href="//commons.wikimedia.org/wiki/User:Tdadamemd" title="User:Tdadamemd">Tdadamemd</a> - <a rel="nofollow" class="external free" href="http://epic.gsfc.nasa.gov/#2015-09-25">http://epic.gsfc.nasa.gov/#2015-09-25</a>, Public Domain, <a href="https://commons.wikimedia.org/w/index.php?curid=49165817">Link</a>
