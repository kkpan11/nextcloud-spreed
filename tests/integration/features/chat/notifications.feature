Feature: chat/notifications

  Background:
    Given user "participant1" exists
    Given user "participant2" exists
    And group "attendees1" exists
    And user "participant2" is member of group "attendees1"

  Scenario: Normal message when recipient is online in the one-to-one
    When user "participant1" creates room "one-to-one room" (v4)
      | roomType | 1 |
      | invite   | participant2 |
    Given user "participant2" joins room "one-to-one room" with 200 (v4)
    When user "participant1" sends message "Message 1" to room "one-to-one room" with 201
    Then user "participant2" has the following notifications
      | app | object_type | object_id | subject |

  Scenario: Normal message when recipient is online but inactive
    When user "participant1" creates room "one-to-one room" (v4)
      | roomType | 1 |
      | invite   | participant2 |
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "one-to-one room" with 200 (v4)
    Given user "participant2" sets session state to 2 in room "one-to-one room" with 400 (v4)
    When user "participant1" sends message "Message 1" to room "one-to-one room" with 201
    Given user "participant2" sets session state to 0 in room "one-to-one room" with 200 (v4)
    When user "participant1" sends message "Message 2" to room "one-to-one room" with 201
    Given user "participant2" sets session state to 1 in room "one-to-one room" with 200 (v4)
    When user "participant1" sends message "Message 3" to room "one-to-one room" with 201
    Then user "participant2" has the following notifications
      | app    | object_type | object_id                 | subject                                             |
      | spreed | chat        | one-to-one room/Message 2 | participant1-displayname sent you a private message |

  Scenario: Normal message when recipient is offline in the one-to-one
    When user "participant1" creates room "one-to-one room" (v4)
      | roomType | 1 |
      | invite   | participant2 |
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "one-to-one room" with 200 (v4)
    Given user "participant2" leaves room "one-to-one room" with 200 (v4)
    When user "participant1" sends message "Message 1" to room "one-to-one room" with 201
    Then user "participant2" has the following notifications
      | app    | object_type | object_id                 | subject                                             |
      | spreed | chat        | one-to-one room/Message 1 | participant1-displayname sent you a private message |

  Scenario: Silent sent message when recipient is offline in the one-to-one
    When user "participant1" creates room "one-to-one room" (v4)
      | roomType | 1 |
      | invite   | participant2 |
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "one-to-one room" with 200 (v4)
    Given user "participant2" leaves room "one-to-one room" with 200 (v4)
    When user "participant1" silent sends message "Message 1" to room "one-to-one room" with 201
    Then user "participant2" has the following notifications
      | app | object_type | object_id | subject |

  Scenario: Normal message when recipient disabled notifications in the one-to-one
    When user "participant1" creates room "one-to-one room" (v4)
      | roomType | 1 |
      | invite   | participant2 |
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "one-to-one room" with 200 (v4)
    Given user "participant2" leaves room "one-to-one room" with 200 (v4)
    And user "participant2" sets notifications to disabled for room "one-to-one room" (v4)
    When user "participant1" sends message "Message 1" to room "one-to-one room" with 201
    Then user "participant2" has the following notifications
      | app | object_type | object_id | subject |

  Scenario: Mention when recipient is online in the one-to-one
    When user "participant1" creates room "one-to-one room" (v4)
      | roomType | 1 |
      | invite   | participant2 |
    Given user "participant2" joins room "one-to-one room" with 200 (v4)
    When user "participant1" sends message "Hi @participant2 bye" to room "one-to-one room" with 201
    Then user "participant2" has the following notifications
      | app    | object_type | object_id                            | subject                                                          |
      | spreed | chat        | one-to-one room/Hi @participant2 bye | participant1-displayname mentioned you in a private conversation |

  Scenario: Mention when recipient is offline in the one-to-one
    When user "participant1" creates room "one-to-one room" (v4)
      | roomType | 1 |
      | invite   | participant2 |
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "one-to-one room" with 200 (v4)
    Given user "participant2" leaves room "one-to-one room" with 200 (v4)
    When user "participant1" sends message "Hi @participant2 bye" to room "one-to-one room" with 201
    Then user "participant2" has the following notifications
      | app    | object_type | object_id                            | subject                                                          |
      | spreed | chat        | one-to-one room/Hi @participant2 bye | participant1-displayname mentioned you in a private conversation |

  Scenario: Mention when recipient disabled notifications in the one-to-one
    When user "participant1" creates room "one-to-one room" (v4)
      | roomType | 1 |
      | invite   | participant2 |
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "one-to-one room" with 200 (v4)
    Given user "participant2" leaves room "one-to-one room" with 200 (v4)
    And user "participant2" sets notifications to disabled for room "one-to-one room" (v4)
    When user "participant1" sends message "Hi @participant2 bye" to room "one-to-one room" with 201
    Then user "participant2" has the following notifications
      | app | object_type | object_id | subject |

  Scenario: Reaction in the one-to-one
    When user "participant1" creates room "one-to-one room" (v4)
      | roomType | 1 |
      | invite   | participant2 |
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "one-to-one room" with 200 (v4)
    Given user "participant2" leaves room "one-to-one room" with 200 (v4)
    When user "participant2" sends message "Message 1" to room "one-to-one room" with 201
    And user "participant1" react with "🚀" on message "Message 1" to room "one-to-one room" with 201
    Then user "participant2" has the following notifications
      | app    | object_type | object_id                 | subject                                                          |
      | spreed | chat        | one-to-one room/Message 1 | participant1-displayname reacted with 🚀 to your private message |

  Scenario: Reaction when recipient disabled notifications in the one-to-one
    When user "participant1" creates room "one-to-one room" (v4)
      | roomType | 1 |
      | invite   | participant2 |
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "one-to-one room" with 200 (v4)
    Given user "participant2" leaves room "one-to-one room" with 200 (v4)
    When user "participant2" sends message "Message 1" to room "one-to-one room" with 201
    And user "participant2" sets notifications to disabled for room "one-to-one room" (v4)
    And user "participant1" react with "🚀" on message "Message 1" to room "one-to-one room" with 201
    Then user "participant2" has the following notifications
      | app | object_type | object_id | subject |

  Scenario: At-all when recipient is online in the one-to-one
    When user "participant1" creates room "one-to-one room" (v4)
      | roomType | 1 |
      | invite   | participant2 |
    Given user "participant2" joins room "one-to-one room" with 200 (v4)
    When user "participant1" sends message "Hi @all bye" to room "one-to-one room" with 201
    Then user "participant2" has the following notifications
      | app    | object_type | object_id                   | subject                                                          |
      | spreed | chat        | one-to-one room/Hi @all bye | participant1-displayname mentioned you in a private conversation |

  Scenario: At-all when recipient is offline in the one-to-one
    When user "participant1" creates room "one-to-one room" (v4)
      | roomType | 1 |
      | invite   | participant2 |
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "one-to-one room" with 200 (v4)
    Given user "participant2" leaves room "one-to-one room" with 200 (v4)
    When user "participant1" sends message "Hi @all bye" to room "one-to-one room" with 201
    Then user "participant2" has the following notifications
      | app    | object_type | object_id                   | subject                                                          |
      | spreed | chat        | one-to-one room/Hi @all bye | participant1-displayname mentioned you in a private conversation |

  Scenario: At-all when recipient disabled notifications in the one-to-one
    When user "participant1" creates room "one-to-one room" (v4)
      | roomType | 1 |
      | invite   | participant2 |
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "one-to-one room" with 200 (v4)
    Given user "participant2" leaves room "one-to-one room" with 200 (v4)
    And user "participant2" sets notifications to disabled for room "one-to-one room" (v4)
    When user "participant1" sends message "Hi @all bye" to room "one-to-one room" with 201
    Then user "participant2" has the following notifications
      | app | object_type | object_id | subject |

  Scenario: Normal message when recipient is online in the group room
    When user "participant1" creates room "room" (v4)
      | roomType | 2 |
      | roomName | room |
    And user "participant1" adds user "participant2" to room "room" with 200 (v4)
    Given user "participant2" joins room "room" with 200 (v4)
    When user "participant1" sends message "Message 1" to room "room" with 201
    Then user "participant2" has the following notifications
      | app | object_type | object_id | subject |

  Scenario: Normal message when recipient is offline in the group room
    When user "participant1" creates room "room" (v4)
      | roomType | 2 |
      | roomName | room |
    And user "participant1" adds user "participant2" to room "room" with 200 (v4)
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "room" with 200 (v4)
    Given user "participant2" leaves room "room" with 200 (v4)
    When user "participant1" sends message "Message 1" to room "room" with 201
    Then user "participant2" has the following notifications
      | app | object_type | object_id | subject |

  Scenario: Normal message when recipient with all notifications in the group room
    When user "participant1" creates room "room" (v4)
      | roomType | 2 |
      | roomName | room |
    And user "participant1" adds user "participant2" to room "room" with 200 (v4)
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "room" with 200 (v4)
    Given user "participant2" leaves room "room" with 200 (v4)
    And user "participant2" sets notifications to all for room "room" (v4)
    When user "participant1" sends message "Message 1" to room "room" with 201
    Then user "participant2" has the following notifications
      | app    | object_type | object_id      | subject                                                      |
      | spreed | chat        | room/Message 1 | participant1-displayname sent a message in conversation room |

  Scenario: Mention when recipient is online in the group room
    When user "participant1" creates room "room" (v4)
      | roomType | 2 |
      | roomName | room |
    And user "participant1" adds user "participant2" to room "room" with 200 (v4)
    Given user "participant2" joins room "room" with 200 (v4)
    When user "participant1" sends message "Hi @participant2 bye" to room "room" with 201
    Then user "participant2" has the following notifications
      | app    | object_type | object_id                 | subject                                                     |
      | spreed | chat        | room/Hi @participant2 bye | participant1-displayname mentioned you in conversation room |

  Scenario: Silent mention when recipient is online in the group room
    When user "participant1" creates room "room" (v4)
      | roomType | 2 |
      | roomName | room |
    And user "participant1" adds user "participant2" to room "room" with 200 (v4)
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "room" with 200 (v4)
    Given user "participant2" leaves room "room" with 200 (v4)
    When user "participant1" silent sends message "Hi @participant2 bye" to room "room" with 201
    Then user "participant2" has the following notifications
      | app | object_type | object_id | subject |

  Scenario: Mention when recipient is offline in the group room
    When user "participant1" creates room "room" (v4)
      | roomType | 2 |
      | roomName | room |
    And user "participant1" adds user "participant2" to room "room" with 200 (v4)
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "room" with 200 (v4)
    Given user "participant2" leaves room "room" with 200 (v4)
    When user "participant1" sends message "Hi @participant2 bye" to room "room" with 201
    Then user "participant2" has the following notifications
      | app    | object_type | object_id                 | subject                                                     |
      | spreed | chat        | room/Hi @participant2 bye | participant1-displayname mentioned you in conversation room |

  Scenario: Mention when recipient with disabled notifications in the group room
    When user "participant1" creates room "room" (v4)
      | roomType | 2 |
      | roomName | room |
    And user "participant1" adds user "participant2" to room "room" with 200 (v4)
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "room" with 200 (v4)
    Given user "participant2" leaves room "room" with 200 (v4)
    And user "participant2" sets notifications to disabled for room "room" (v4)
    When user "participant1" sends message "Hi @participant2 bye" to room "room" with 201
    Then user "participant2" has the following notifications
      | app | object_type | object_id | subject |

  Scenario: At-all when recipient is online in the group room
    When user "participant1" creates room "room" (v4)
      | roomType | 2 |
      | roomName | room |
    And user "participant1" adds user "participant2" to room "room" with 200 (v4)
    Given user "participant2" joins room "room" with 200 (v4)
    When user "participant1" sends message "Hi @all bye" to room "room" with 201
    Then user "participant2" has the following notifications
      | app    | object_type | object_id        | subject                                                          |
      | spreed | chat        | room/Hi @all bye | participant1-displayname mentioned everyone in conversation room |

  Scenario: At-all when recipient is offline in the group room
    When user "participant1" creates room "room" (v4)
      | roomType | 2 |
      | roomName | room |
    And user "participant1" adds user "participant2" to room "room" with 200 (v4)
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "room" with 200 (v4)
    Given user "participant2" leaves room "room" with 200 (v4)
    When user "participant1" sends message "Hi @all bye" to room "room" with 201
    Then user "participant2" has the following notifications
      | app    | object_type | object_id        | subject                                                          |
      | spreed | chat        | room/Hi @all bye | participant1-displayname mentioned everyone in conversation room |

  Scenario: Silent at-all when recipient is offline in the group room
    When user "participant1" creates room "room" (v4)
      | roomType | 2 |
      | roomName | room |
    And user "participant1" adds user "participant2" to room "room" with 200 (v4)
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "room" with 200 (v4)
    Given user "participant2" leaves room "room" with 200 (v4)
    When user "participant1" silent sends message "Hi @all bye" to room "room" with 201
    Then user "participant2" has the following notifications
      | app | object_type | object_id | subject |

  Scenario: At-all when recipient with disabled notifications in the group room
    When user "participant1" creates room "room" (v4)
      | roomType | 2 |
      | roomName | room |
    And user "participant1" adds user "participant2" to room "room" with 200 (v4)
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "room" with 200 (v4)
    Given user "participant2" leaves room "room" with 200 (v4)
    And user "participant2" sets notifications to disabled for room "room" (v4)
    When user "participant1" sends message "Hi @all bye" to room "room" with 201
    Then user "participant2" has the following notifications
      | app | object_type | object_id | subject |

  Scenario: Group-mention when recipient is online in the group room
    When user "participant1" creates room "room" (v4)
      | roomType | 2 |
      | roomName | room |
    And user "participant1" adds user "participant2" to room "room" with 200 (v4)
    And user "participant1" adds group "attendees1" to room "room" with 200 (v4)
    Given user "participant2" joins room "room" with 200 (v4)
    When user "participant1" sends message 'Hi @"group/attendees1" bye' to room "room" with 201
    Then user "participant2" has the following notifications
      | app    | object_type | object_id        | subject                                                     |
      | spreed | chat        | room/Hi @"group/attendees1" bye | participant1-displayname mentioned group attendees1 in conversation room |

  Scenario: Group-mention when group is not a member of the room
    When user "participant1" creates room "room" (v4)
      | roomType | 2 |
      | roomName | room |
    And user "participant1" adds user "participant2" to room "room" with 200 (v4)
    Given user "participant2" joins room "room" with 200 (v4)
    When user "participant1" sends message 'Hi @"group/attendees1" bye' to room "room" with 201
    Then user "participant2" has the following notifications
      | app | object_type | object_id | subject |

  Scenario: Group-mention when recipient is offline in the group room
    When user "participant1" creates room "room" (v4)
      | roomType | 2 |
      | roomName | room |
    And user "participant1" adds user "participant2" to room "room" with 200 (v4)
    And user "participant1" adds group "attendees1" to room "room" with 200 (v4)
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "room" with 200 (v4)
    Given user "participant2" leaves room "room" with 200 (v4)
    When user "participant1" sends message 'Hi @"group/attendees1" bye' to room "room" with 201
    Then user "participant2" has the following notifications
      | app    | object_type | object_id        | subject                                                     |
      | spreed | chat        | room/Hi @"group/attendees1" bye | participant1-displayname mentioned group attendees1 in conversation room |

  Scenario: Silent group-mention when recipient is offline in the group room
    When user "participant1" creates room "room" (v4)
      | roomType | 2 |
      | roomName | room |
    And user "participant1" adds user "participant2" to room "room" with 200 (v4)
    And user "participant1" adds group "attendees1" to room "room" with 200 (v4)
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "room" with 200 (v4)
    Given user "participant2" leaves room "room" with 200 (v4)
    When user "participant1" silent sends message 'Hi @"group/attendees1" bye' to room "room" with 201
    Then user "participant2" has the following notifications
      | app | object_type | object_id | subject |

  Scenario: Group-mention when recipient with disabled notifications in the group room
    When user "participant1" creates room "room" (v4)
      | roomType | 2 |
      | roomName | room |
    And user "participant1" adds user "participant2" to room "room" with 200 (v4)
    And user "participant1" adds group "attendees1" to room "room" with 200 (v4)
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "room" with 200 (v4)
    Given user "participant2" leaves room "room" with 200 (v4)
    And user "participant2" sets notifications to disabled for room "room" (v4)
    When user "participant1" sends message 'Hi @"group/attendees1" bye' to room "room" with 201
    Then user "participant2" has the following notifications
      | app | object_type | object_id | subject |

  Scenario: Replying with all mention types only gives a reply notification
    When user "participant1" creates room "room" (v4)
      | roomType | 2 |
      | roomName | room |
    And user "participant1" adds user "participant2" to room "room" with 200 (v4)
    And user "participant1" adds group "attendees1" to room "room" with 200 (v4)
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "room" with 200 (v4)
    Given user "participant2" leaves room "room" with 200 (v4)
    When user "participant2" sends message "Hi part 1" to room "room" with 201
    When user "participant1" sends reply 'Hi @all @participant2 @"group/attendees1" bye' on message "Hi part 1" to room "room" with 201
    Then user "participant2" has the following notifications
      | app    | object_type | object_id        | subject                                                     |
      | spreed | chat        | room/Hi @all @participant2 @"group/attendees1" bye | participant1-displayname replied to your message in conversation room |

  Scenario: Delete notification when the message is deleted
    When user "participant1" creates room "one-to-one room" (v4)
      | roomType | 1 |
      | invite   | participant2 |
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "one-to-one room" with 200 (v4)
    And user "participant2" leaves room "one-to-one room" with 200 (v4)
    And user "participant1" sends message "Message 1" to room "one-to-one room" with 201
    Then user "participant2" has the following notifications
      | app    | object_type | object_id                 | subject                                             |
      | spreed | chat        | one-to-one room/Message 1 | participant1-displayname sent you a private message |
    When user "participant1" deletes message "Message 1" from room "one-to-one room" with 200 (v1)
    Then user "participant2" has the following notifications
      | app | object_type | object_id | subject |

  Scenario: Reaction when recipient full enables notifications in the group room
    When user "participant1" creates room "room" (v4)
      | roomType | 2 |
      | roomName | room |
    And user "participant1" adds user "participant2" to room "room" with 200 (v4)
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "room" with 200 (v4)
    Given user "participant2" leaves room "room" with 200 (v4)
    When user "participant2" sends message "Message 1" to room "room" with 201
    And user "participant2" sets notifications to all for room "room" (v4)
    And user "participant1" react with "🚀" on message "Message 1" to room "room" with 201
    Then user "participant2" has the following notifications
      | app    | object_type | object_id                 | subject                                                            |
      | spreed | chat        | room/Message 1 | participant1-displayname reacted with 🚀 to your message in conversation room |

  Scenario: Reaction when recipient has default notifications (disabled) in the group room
    When user "participant1" creates room "room" (v4)
      | roomType | 2 |
      | roomName | room |
    And user "participant1" adds user "participant2" to room "room" with 200 (v4)
    # Join and leave to clear the invite notification
    Given user "participant2" joins room "room" with 200 (v4)
    Given user "participant2" leaves room "room" with 200 (v4)
    When user "participant2" sends message "Message 1" to room "room" with 201
    And user "participant1" react with "🚀" on message "Message 1" to room "room" with 201
    Then user "participant2" has the following notifications
      | app | object_type | object_id | subject |

  Scenario: Lobby: No notifications while being blocked by the lobby
    Given user "participant1" creates room "room" (v4)
      | roomType | 2 |
      | roomName | room |
    And user "participant1" adds user "participant2" to room "room" with 200 (v4)
    # Join and leave to clear the invite notification
    And user "participant2" joins room "room" with 200 (v4)
    And user "participant2" leaves room "room" with 200 (v4)
    And user "participant2" sends message "Message 1" to room "room" with 201
    And user "participant2" sets notifications to all for room "room" (v4)
    And user "participant1" sets lobby state for room "room" to "non moderators" with 200 (v4)
    When user "participant1" sends message "Hi @all bye" to room "room" with 201
    And user "participant1" react with "🚀" on message "Message 1" to room "room" with 201
    When user "participant1" sends message "Hi @participant2" to room "room" with 201
    Then user "participant2" has the following notifications
      | app | object_type | object_id | subject |

  Scenario: Lobby: Notifications for users that ignore the lobby
    Given user "participant1" creates room "room" (v4)
      | roomType | 2 |
      | roomName | room |
    And user "participant1" adds user "participant2" to room "room" with 200 (v4)
    # Join and leave to clear the invite notification
    And user "participant2" joins room "room" with 200 (v4)
    And user "participant2" leaves room "room" with 200 (v4)
    And user "participant2" sends message "Message 1" to room "room" with 201
    And user "participant2" sets notifications to all for room "room" (v4)
    And user "participant1" sets lobby state for room "room" to "non moderators" with 200 (v4)
    And user "participant1" sets permissions for "participant2" in room "room" to "L" with 200 (v4)
    And user "participant1" sends message "Hi @all bye" to room "room" with 201
    And user "participant1" react with "🚀" on message "Message 1" to room "room" with 201
    When user "participant1" sends message "Hi @participant2" to room "room" with 201
    Then user "participant2" has the following notifications
      | app    | object_type | object_id                 | subject                                                                       |
      | spreed | chat        | room/Hi @participant2     | participant1-displayname mentioned you in conversation room                   |
      | spreed | chat        | room/Message 1            | participant1-displayname reacted with 🚀 to your message in conversation room |
      | spreed | chat        | room/Hi @all bye          | participant1-displayname mentioned everyone in conversation room              |

  Scenario: Lobby: Notifications for moderators
    Given user "participant1" creates room "room" (v4)
      | roomType | 2 |
      | roomName | room |
    And user "participant1" adds user "participant2" to room "room" with 200 (v4)
    # Join and leave to clear the invite notification
    And user "participant2" joins room "room" with 200 (v4)
    And user "participant2" leaves room "room" with 200 (v4)
    And user "participant2" sends message "Message 1" to room "room" with 201
    And user "participant2" sets notifications to all for room "room" (v4)
    And user "participant1" sets lobby state for room "room" to "non moderators" with 200 (v4)
    And user "participant1" promotes "participant2" in room "room" with 200 (v4)
    And user "participant1" sends message "Hi @all bye" to room "room" with 201
    And user "participant1" react with "🚀" on message "Message 1" to room "room" with 201
    When user "participant1" sends message "Hi @participant2" to room "room" with 201
    Then user "participant2" has the following notifications
      | app    | object_type | object_id                 | subject                                                                       |
      | spreed | chat        | room/Hi @participant2     | participant1-displayname mentioned you in conversation room                   |
      | spreed | chat        | room/Message 1            | participant1-displayname reacted with 🚀 to your message in conversation room |
      | spreed | chat        | room/Hi @all bye          | participant1-displayname mentioned everyone in conversation room              |

  Scenario: Lobby: Wipe notifications when being blocked by the lobby
    Given user "participant1" creates room "room" (v4)
      | roomType | 2 |
      | roomName | room |
    And user "participant1" adds user "participant2" to room "room" with 200 (v4)
    # Join and leave to clear the invite notification
    And user "participant2" joins room "room" with 200 (v4)
    And user "participant2" leaves room "room" with 200 (v4)
    And user "participant2" sends message "Message 1" to room "room" with 201
    And user "participant2" sets notifications to all for room "room" (v4)
    And user "participant1" sends message "Hi @all bye" to room "room" with 201
    And user "participant1" react with "🚀" on message "Message 1" to room "room" with 201
    And user "participant1" sends message "Hi @participant2" to room "room" with 201
    Then user "participant2" has the following notifications
      | app    | object_type | object_id                 | subject                                                                       |
      | spreed | chat        | room/Hi @participant2     | participant1-displayname mentioned you in conversation room                   |
      | spreed | chat        | room/Message 1            | participant1-displayname reacted with 🚀 to your message in conversation room |
      | spreed | chat        | room/Hi @all bye          | participant1-displayname mentioned everyone in conversation room              |
    When user "participant1" sets lobby state for room "room" to "non moderators" with 200 (v4)
    Then user "participant2" has the following notifications
      | app | object_type | object_id | subject |
