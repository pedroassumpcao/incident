# Changelog

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/).

## [0.6.0] - 2020-12-10

### Added

#### Library

- Handle race conditions and concurrent scenarios during command execution;
- Add `EventStoreSupervisor` to supervise `EventStore` adapters and `LockManager`;
- Add `AggregateLock` schema to hold lock data;

#### Bank Example Application

- Add integration tests that exercise concurrency and race conditions;

### Changed

#### Library

- Change how `Incident` is configured and added in the application supervision tree;
- Update `mix incident.postgres.init` to include migration for `aggregate_locks` table;
- Update documentation regarding library configuration and usage;
- Update package dependencies;

#### Bank Example Application

- Update documentation regarding library configuration and usage;

## [0.5.1] - 2020-11-03

### Changed

#### Library

- Add `id` for the in memory event data structure;
- Sort events by `id` in the Event Store `Postgres` and `InMemory` adapters to ensure proper event ordering;
- Remove `updated_at` column from `events` table in the `mix incident.postgres.init` task;
- Update documentation;
- Update package dependencies;

#### Bank Example Application

- Update `events` migration to reflect changes in the `mix incident.postgres.init` task;

## [0.5.0] - 2020-10-15

### Added

#### Library

- Add `get/2` for Projection Store `InMemory` and `Postgres` adapters to fetch a projection for a specific
aggregate;

#### Bank Example Application

- Add `Transfer`, `TransferCommandhandler`, `TransferState` and `TransferEventHandler` to
demonstrate an example of **aggregate root** use-case;
- Add examples of events that can generate specific commands in `TransferEventHandler` to
demonstrate sequence of **Event -> Command -> Event** use-cases;

### Changed

#### Library

- The `CommandHandler` now returns `{:ok, persisted_event}` instead of just `:ok`, allowing event
handlers to compose a new command and call the `CommandHandler` based on the previous event. This
allows a series of **Event -> Command -> Event** to be built;
- Set Elixir minimum version to 1.8;
- Update package dependencies;

#### Bank Example Application

- Rename `Bank.EventHandler` to `Bank.BankAccountEventHandler` to make it clear that this
handler is only for the `BankAccount` aggregate events as now we have more than one aggregate;
- Set Elixir minimum version to 1.8;

## [0.4.1] - 2020-06-18

### Changed

#### Library

- Update package dependencies;

## [0.4.0] - 2019-10-06

### Added

#### Library

- Add `mix incident.postgres.init` mix task to set up `Postgres` as Event Store storage;

#### Bank Example Application

- Add `WithdrawMoney` command, `MoneyWithdrawn` event, and business logic;

### Changed

#### Library

- Update package dependencies;

## [0.3.0] — 2019-09-14

### Added

#### Library

- Add `Postgres` adapter for events;
- Add `Postgres` adapter for projections;
- Set up continuous integration with Circle CI;

#### Bank Example Application

- Add integration tests for `InMemoryAdapter`;
- Add integration tests for `PostgresAdapter`;

### Changed

#### Library

- Specify separate event data structures for `InMemoryAdapter` and `PostgresAdapter`;

#### Bank Example Application

- Use `PostgresAdapter` as default;
- Update readme file;

## [0.2.0] — 2019-07-16

### Added

#### Library

- Define the `Incident.Command` behaviour to specify the command interface;
- Define the `Incident.CommandHandler` macro for command handlers;
- Define the `Incident.EventHandler` behaviour to specify the event handler interface;
- Use `Ecto.Schema` event data structure;
- Use `Ecto.Schema` for command data structure;

### Changed

#### Library

- Move event persistency from aggregates to command handlers;
- Validate commands in the command handlers using command implementation;

## [0.1.0] — 2019-06-19

#### Library

- Initial release with base functionality with In Memory adapters;
- Initial release for the bank example application;
