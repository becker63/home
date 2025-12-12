def _python_codegen_impl(ctx):
    out = ctx.actions.declare_output("generated_models", dir=True)

    codegen = ctx.attrs._codegen[RunInfo]
    ruff = ctx.attrs._ruff[RunInfo]

    args = cmd_args()
    args.add(ctx.attrs.namespace)

    for f in ctx.attrs.srcs:
        args.add("--input", f)

    args.add("--output", out.as_output())
    args.add("--clean")

    shell_cmd = cmd_args(
        [
            "bash",
            "-e",
            "-c",
            cmd_args(
                [
                    # prepend ruff and call codegen
                    "PATH=$(dirname ",
                    cmd_args(ruff, format="{}"),
                    "):$PATH;",
                    codegen,
                    args,
                ],
                delimiter=" "
            ),
        ]
    )

    ctx.actions.run(
        shell_cmd,
        category="python_codegen"
    )

    return [DefaultInfo(default_outputs=[out])]


python_codegen = rule(
    impl = _python_codegen_impl,
    attrs = {
        "srcs": attrs.list(attrs.source(), default=[]),
        "namespace": attrs.string(),
        "_codegen": attrs.exec_dep(default="//src/codegen/python:codegen"),
        "_ruff": attrs.exec_dep(default="toolchains//:ruff"),
    },
)
