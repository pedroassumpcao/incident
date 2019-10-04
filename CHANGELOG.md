# Changelog

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/).

## [Unreleased]

- Add `mix incident.postgres.init` mix task to set up `Postgres` as Event Store storage;
- Update package dependencies;
- Add `WithdrawMoney` command, `MoneyWithdrawn` event, and business logic in the bank example application;

## [0.3.0] — 2019-09-14

### Added

- Add `Postgres` adapter for events;
- Add `Postgres` adapter for projections;
- Set up continuous integration with Circle CI;
- Add integration tests for `InMemoryAdapter` in the bank example application;
- Add integration tests for `PostgresAdapter` in the bank example application;

### Changed

- Specify separate event data structures for `InMemoryAdapter` and `PostgresAdapter`;
- Use `PostgresAdapter` in the bank example application as default;
- Update bank example application readme file;

## [0.2.0] — 2019-07-16

### Added

- Define the `Incident.Command` behaviour to specify the command interface;
- Define the `Incident.CommandHandler` macro for command handlers;
- Define the `Incident.EventHandler` behaviour to specify the event handler interface;
- Use `Ecto.Schema` event data structure;
- Use `Ecto.Schema` for command data structure;

### Changed

- Move event persistency from aggregates to command handlers;
- Validate commands in the command handlers using command implementation;

## [0.1.0] — 2019-06-19

- Initial release with base functionality with In Memory adapters;
- Initial release for the bank example application;
