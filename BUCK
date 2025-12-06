command_alias(
    name = "hello",
    args = [
        "-c",
        'import sys; print(f"hello, from Python {sys.version}")',
    ],
    exe = "toolchains//:python",  # use python from toolchains
)

command_alias(
    name = "weather",
    args = ["wttr.in/?0"],
    exe = "toolchains//:curl",    # use curl from toolchains
)
