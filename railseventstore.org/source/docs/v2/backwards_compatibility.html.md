---
title: Backwards compatibility
---

## Backwards compatibility

Rails Event Store project aims to follow [semver](https://semver.org). There are a couple of situations which may be perceived as exceptions from following it and they are described in this article.

### Ruby versions

Our aim is to only support ruby versions which are not EOL. Therefore:

1. Whenever new minor ruby version is released, we start testing against it on CI and if changes are needed to support it, they are shipped with priority.
2. Whenever ruby version goes EOL, the support for it is dropped in next minor version without any consideration.

On CI, all latest minor versions of CRuby are tested. Currently other Ruby implementations are not supported, but we are open to changing that situation depending on external funding.

### Rails versions

Our aim is to support all Rails versions which are not EOL.

Similar to Ruby version compatibility, whenever Rails version goes EOL, we drop the support for it in next minor version without any consideration.

On CI, we test _some_ of the projects on all minor Rails versions, other ones only against newest minor Rails version. That's because CI capacity is limited and we value quick feedback loop for our changes.

### Experimental features

Some of the functionalities are marked in the documentation as experimental. This means that we are still in process of discovery of the stable API for them, and therefore, the API of them may change breaking backwards compatibility between subsequent minor versions.

Breaking that compatibility should be limited only to the area of experimental features, meaning, that if you don't use any experimental functionalities, you shouldn't be in any way affected by API changing from version to version.
