# RubyEventStore::Transformations

Additional transformations for PipelineMapper.

Currently consists of:

- IdentityMap

  Loads records into previously-known event instances, retaining their object_id.
  Useful in some test asserting on inpect output.

- WithIndifferentAccess

  Deep-symbolizes data and metadata before writing, decorates with HashWithIndifferentAccess on reads.
  Useful for JSON-backed data and metadata.
