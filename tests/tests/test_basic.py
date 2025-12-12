from generated.fluxcd_helm.fluxcd_helm.io.fluxcd.toolkit.helm.v2 import HelmRelease


def test_basic(dummy):
    print("Contents of instantiated generated helmrelease: ")
    print(HelmRelease)
    assert dummy == "hello from fixture"
