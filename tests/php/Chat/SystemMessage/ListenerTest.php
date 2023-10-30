<?php
/**
 * @copyright Copyright (c) 2020 Vincent Petry <vincent@nextcloud.com>
 *
 * @license GNU AGPL version 3 or any later version
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

namespace OCA\Talk\Tests\php\Chat\SystemMessage;

use OCA\Talk\Chat\ChatManager;
use OCA\Talk\Chat\SystemMessage\Listener;
use OCA\Talk\Events\AddParticipantsEvent;
use OCA\Talk\Events\ModifyParticipantEvent;
use OCA\Talk\Events\ModifyRoomEvent;
use OCA\Talk\Model\Attendee;
use OCA\Talk\Participant;
use OCA\Talk\Room;
use OCA\Talk\TalkSession;
use OCP\AppFramework\Utility\ITimeFactory;
use OCP\Comments\IComment;
use OCP\EventDispatcher\IEventDispatcher;
use OCP\IRequest;
use OCP\ISession;
use OCP\IUser;
use OCP\IUserSession;
use PHPUnit\Framework\Assert;
use PHPUnit\Framework\MockObject\MockObject;
use Test\TestCase;

/**
 * @group DB
 */
class ListenerTest extends TestCase {
	public const DUMMY_REFERENCE_ID = 'DUMMY_REFERENCE_ID';

	protected ?Listener $listener = null;

	/** @var IRequest|MockObject */
	protected $request;
	/** @var ChatManager|MockObject */
	protected $chatManager;
	/** @var IUserSession|MockObject */
	protected $userSession;
	/** @var ISession|MockObject */
	protected $session;
	/** @var TalkSession|MockObject */
	protected $talkSession;
	/** @var ITimeFactory|MockObject */
	protected $timeFactory;
	/** @var IEventDispatcher|MockObject */
	protected $eventDispatcher;
	protected ?array $handlers = null;
	protected ?\DateTime $dummyTime = null;

	protected function setUp(): void {
		parent::setUp();

		$this->request = $this->createMock(IRequest::class);
		$this->request->expects($this->any())
			->method('getParam')
			->with('referenceId')
			->willReturn(self::DUMMY_REFERENCE_ID);

		$this->dummyTime = new \DateTime();

		$this->chatManager = $this->createMock(ChatManager::class);
		$this->session = $this->createMock(ISession::class);
		$this->userSession = $this->createMock(IUserSession::class);
		$this->talkSession = $this->createMock(TalkSession::class);
		$this->timeFactory = $this->createMock(ITimeFactory::class);
		$this->timeFactory->method('getDateTime')->willReturn($this->dummyTime);
		$this->eventDispatcher = $this->createMock(IEventDispatcher::class);

		$this->handlers = [];

		$this->eventDispatcher->method('addListener')
			->will($this->returnCallback(function ($eventName, $handler) {
				$this->handlers[$eventName] ??= [];
				$this->handlers[$eventName][] = $handler;
			}));

		$this->listener = new Listener(
			$this->request,
			$this->chatManager,
			$this->talkSession,
			$this->session,
			$this->userSession,
			$this->timeFactory
		);

		$this->overwriteService(Listener::class, $this->listener);
		$this->listener->register($this->eventDispatcher);
	}

	public function tearDown(): void {
		$this->restoreService(Listener::class);
		$this->logout();

		parent::tearDown();
	}

	private function dispatch($eventName, $event) {
		$handlers = $this->handlers[$eventName];
		$this->assertCount(1, $handlers);

		$handlers[0]($event);
	}

	private function mockLoggedInUser($userId): IUser {
		$user = $this->createMock(IUser::class);
		$user->method('getUID')->willReturn($userId);
		$this->userSession
			->method('getUser')
			->willReturn($user);

		return $user;
	}

	public function testAfterUsersAddOneToOne(): void {
		$room = $this->createMock(Room::class);
		$room->expects($this->any())
			->method('getType')
			->willReturn(Room::TYPE_ONE_TO_ONE);

		$participants = [[
			'actorType' => 'users',
			'actorId' => 'alice_actor',
			'participantType' => Participant::USER,
		]];
		$event = new AddParticipantsEvent($room, $participants);

		$this->chatManager->expects($this->never())
			->method('addSystemMessage');

		$this->dispatch(Room::EVENT_AFTER_USERS_ADD, $event);
	}

	public static function dataRoomTypes(): array {
		$expectedMessages = [
			[
				'actorType' => 'users',
				'actorId' => 'alice_actor',
				'message' => ['message' => 'user_added', 'parameters' => ['user' => 'alice_actor']],
			],
			[
				'actorType' => 'users',
				'actorId' => 'alice_actor',
				'message' => ['message' => 'user_added', 'parameters' => ['user' => 'bob']],
			],
			[
				'actorType' => 'users',
				'actorId' => 'alice_actor',
				'message' => ['message' => 'user_added', 'parameters' => ['user' => 'carmen']],
			],
			[
				'actorType' => 'users',
				'actorId' => 'alice_actor',
				'message' => ['message' => 'user_added', 'parameters' => ['user' => 'delta']],
			],
		];

		$allParticipants = [
			// guest will be ignored
			[
				'actorType' => 'guests'
			],
			// alice_actor adding self to listed channel
			[
				'actorType' => 'users',
				'actorId' => 'alice_actor',
				'participantType' => Participant::USER,
			],
			// alice_actor added bob
			[
				'actorType' => 'users',
				'actorId' => 'bob',
				'participantType' => Participant::USER,
			],
			// empty participant type
			[
				'actorType' => 'users',
				'actorId' => 'carmen',
			],
			// alice_actor adding self-joined mode
			[
				'actorType' => 'users',
				'actorId' => 'delta',
				'participantType' => Participant::USER_SELF_JOINED,
			],
		];

		return [
			[Room::TYPE_GROUP, '', $allParticipants, $expectedMessages],
			[Room::TYPE_PUBLIC, '', $allParticipants, $expectedMessages],
			[Room::TYPE_ONE_TO_ONE, '', $allParticipants, []],
			[Room::TYPE_GROUP, 'file', $allParticipants, $expectedMessages],
			[Room::TYPE_PUBLIC, 'file', $allParticipants, $expectedMessages],
		];
	}

	/**
	 * @dataProvider dataRoomTypes
	 *
	 * @param int $roomType
	 */
	public function testAfterUsersAdd(int $roomType, string $objectType, array $participants, array $expectedMessages): void {
		$this->mockLoggedInUser('alice_actor');

		$room = $this->createMock(Room::class);
		$room->method('getType')->willReturn($roomType);
		$room->method('getObjectType')->willReturn($objectType);

		// TODO: add all cases
		$event = new AddParticipantsEvent($room, $participants);

		$consecutive = [];
		foreach ($expectedMessages as $expectedMessage) {
			$consecutive[] = [
				$room,
				$expectedMessage['actorType'],
				$expectedMessage['actorId'],
				json_encode($expectedMessage['message']),
				$this->dummyTime,
				false,
				self::DUMMY_REFERENCE_ID,
				null,
				false,
			];
		}
		if (!empty($consecutive)) {
			$i = 0;
			$this->chatManager->expects($this->exactly(count($consecutive)))
				->method('addSystemMessage')
				->willReturnCallback(function () use ($consecutive, &$i) {
					Assert::assertArrayHasKey($i, $consecutive);
					Assert::assertSame($consecutive[$i], func_get_args());
					$i++;
					return $this->createMock(IComment::class);
				});
		}

		$this->dispatch(Room::EVENT_AFTER_USERS_ADD, $event);
	}

	public static function dataParticipantTypeChange(): array {
		return [
			[
				Attendee::ACTOR_EMAILS,
				Participant::USER,
				Participant::MODERATOR,
				[],
			],
			[
				Attendee::ACTOR_USERS,
				Participant::USER,
				Participant::MODERATOR,
				[['message' => 'moderator_promoted', 'parameters' => ['user' => 'bob_participant']]],
			],
			[
				Attendee::ACTOR_USERS,
				Participant::MODERATOR,
				Participant::USER,
				[['message' => 'moderator_demoted', 'parameters' => ['user' => 'bob_participant']]],
			],
			[
				Attendee::ACTOR_GUESTS,
				Participant::GUEST,
				Participant::GUEST_MODERATOR,
				[['message' => 'guest_moderator_promoted', 'parameters' => ['session' => 'bob_participant']]],
			],
			[
				Attendee::ACTOR_GUESTS,
				Participant::GUEST_MODERATOR,
				Participant::GUEST,
				[['message' => 'guest_moderator_demoted', 'parameters' => ['session' => 'bob_participant']]],
			],
			[
				Attendee::ACTOR_USERS,
				Participant::USER_SELF_JOINED,
				Participant::USER,
				[['message' => 'user_added', 'parameters' => ['user' => 'bob_participant']]],
			],
		];
	}

	/**
	 * @dataProvider dataParticipantTypeChange
	 */
	public function testAfterParticipantTypeSet(string $actorType, int $oldParticipantType, int $newParticipantType, array $expectedMessages): void {
		$this->mockLoggedInUser('alice_actor');

		$room = $this->createMock(Room::class);
		$room->method('getType')->willReturn(Room::TYPE_GROUP);

		$attendee = new Attendee();
		$attendee->setActorId('bob_participant');
		$attendee->setActorType($actorType);

		$participant = $this->createMock(Participant::class);
		$participant->method('getAttendee')->willReturn($attendee);

		$event = new ModifyParticipantEvent($room, $participant, '', $newParticipantType, $oldParticipantType);

		foreach ($expectedMessages as $expectedMessage) {
			$consecutive[] = [
				$room,
				Attendee::ACTOR_USERS,
				'alice_actor',
				json_encode($expectedMessage),
				$this->dummyTime,
				false,
				self::DUMMY_REFERENCE_ID,
				null,
				false,
			];
		}
		if (isset($consecutive)) {
			$i = 0;
			$this->chatManager->expects($this->exactly(count($consecutive)))
				->method('addSystemMessage')
				->willReturnCallback(function () use ($consecutive, &$i) {
					Assert::assertArrayHasKey($i, $consecutive);
					Assert::assertSame($consecutive[$i], func_get_args());
					$i++;
					return $this->createMock(IComment::class);
				});
		}

		$this->dispatch(Room::EVENT_AFTER_PARTICIPANT_TYPE_SET, $event);
	}

	public static function dataCallRecordingChange(): array {
		return [
			[
				Room::RECORDING_VIDEO_STARTING,
				Room::RECORDING_NONE,
				null,
				null,
				null,
			],
			[
				Room::RECORDING_VIDEO_STARTING,
				Room::RECORDING_NONE,
				Attendee::ACTOR_USERS,
				'alice',
				null,
			],
			[
				Room::RECORDING_VIDEO,
				Room::RECORDING_VIDEO_STARTING,
				null,
				null,
				['message' => 'recording_started', 'parameters' => []],
			],
			[
				Room::RECORDING_VIDEO,
				Room::RECORDING_VIDEO_STARTING,
				Attendee::ACTOR_USERS,
				'alice',
				['message' => 'recording_started', 'parameters' => []],
			],
			[
				Room::RECORDING_VIDEO,
				Room::RECORDING_NONE,
				null,
				null,
				['message' => 'recording_started', 'parameters' => []],
			],
			[
				Room::RECORDING_VIDEO,
				Room::RECORDING_NONE,
				Attendee::ACTOR_USERS,
				'alice',
				['message' => 'recording_started', 'parameters' => []],
			],
			[
				Room::RECORDING_AUDIO_STARTING,
				Room::RECORDING_NONE,
				null,
				null,
				null,
			],
			[
				Room::RECORDING_AUDIO_STARTING,
				Room::RECORDING_NONE,
				Attendee::ACTOR_USERS,
				'alice',
				null,
			],
			[
				Room::RECORDING_AUDIO,
				Room::RECORDING_AUDIO_STARTING,
				null,
				null,
				['message' => 'audio_recording_started', 'parameters' => []],
			],
			[
				Room::RECORDING_AUDIO,
				Room::RECORDING_AUDIO_STARTING,
				Attendee::ACTOR_USERS,
				'alice',
				['message' => 'audio_recording_started', 'parameters' => []],
			],
			[
				Room::RECORDING_AUDIO,
				Room::RECORDING_NONE,
				null,
				null,
				['message' => 'audio_recording_started', 'parameters' => []],
			],
			[
				Room::RECORDING_AUDIO,
				Room::RECORDING_NONE,
				Attendee::ACTOR_USERS,
				'alice',
				['message' => 'audio_recording_started', 'parameters' => []],
			],
			[
				Room::RECORDING_NONE,
				Room::RECORDING_VIDEO_STARTING,
				null,
				null,
				null,
			],
			[
				Room::RECORDING_NONE,
				Room::RECORDING_VIDEO_STARTING,
				Attendee::ACTOR_USERS,
				'bob',
				null,
			],
			[
				Room::RECORDING_NONE,
				Room::RECORDING_VIDEO,
				null,
				null,
				null,
			],
			[
				Room::RECORDING_NONE,
				Room::RECORDING_VIDEO,
				Attendee::ACTOR_USERS,
				'bob',
				['message' => 'recording_stopped', 'parameters' => []],
			],
			[
				Room::RECORDING_NONE,
				Room::RECORDING_AUDIO_STARTING,
				null,
				null,
				null,
			],
			[
				Room::RECORDING_NONE,
				Room::RECORDING_AUDIO_STARTING,
				Attendee::ACTOR_USERS,
				'bob',
				null,
			],
			[
				Room::RECORDING_NONE,
				Room::RECORDING_AUDIO,
				null,
				null,
				null,
			],
			[
				Room::RECORDING_NONE,
				Room::RECORDING_AUDIO,
				Attendee::ACTOR_USERS,
				'bob',
				['message' => 'audio_recording_stopped', 'parameters' => []],
			],
			[
				Room::RECORDING_FAILED,
				Room::RECORDING_VIDEO_STARTING,
				null,
				null,
				null,
			],
			[
				Room::RECORDING_FAILED,
				Room::RECORDING_AUDIO_STARTING,
				null,
				null,
				null,
			],
			[
				Room::RECORDING_FAILED,
				Room::RECORDING_VIDEO,
				null,
				null,
				['message' => 'recording_failed', 'parameters' => []],
			],
			[
				Room::RECORDING_FAILED,
				Room::RECORDING_AUDIO,
				null,
				null,
				['message' => 'recording_failed', 'parameters' => []],
			],
			[
				Room::RECORDING_VIDEO_STARTING,
				Room::RECORDING_FAILED,
				null,
				null,
				null,
			],
			[
				Room::RECORDING_VIDEO_STARTING,
				Room::RECORDING_FAILED,
				Attendee::ACTOR_USERS,
				'alice',
				null,
			],
			[
				Room::RECORDING_VIDEO,
				Room::RECORDING_FAILED,
				null,
				null,
				['message' => 'recording_started', 'parameters' => []],
			],
			[
				Room::RECORDING_VIDEO,
				Room::RECORDING_FAILED,
				Attendee::ACTOR_USERS,
				'alice',
				['message' => 'recording_started', 'parameters' => []],
			],
			[
				Room::RECORDING_AUDIO_STARTING,
				Room::RECORDING_FAILED,
				null,
				null,
				null,
			],
			[
				Room::RECORDING_AUDIO_STARTING,
				Room::RECORDING_FAILED,
				Attendee::ACTOR_USERS,
				'alice',
				null,
			],
			[
				Room::RECORDING_AUDIO,
				Room::RECORDING_FAILED,
				null,
				null,
				['message' => 'audio_recording_started', 'parameters' => []],
			],
			[
				Room::RECORDING_AUDIO,
				Room::RECORDING_FAILED,
				Attendee::ACTOR_USERS,
				'alice',
				['message' => 'audio_recording_started', 'parameters' => []],
			],
		];
	}

	/**
	 * @dataProvider dataCallRecordingChange
	 */
	public function testAfterCallRecordingSet(int $newStatus, int $oldStatus, ?string $actorType, ?string $actorId, ?array $expectedMessage): void {
		$this->mockLoggedInUser('logged_in_user');

		$room = $this->createMock(Room::class);
		$room->expects($this->any())
			->method('getType')
			->willReturn(Room::TYPE_PUBLIC);

		if ($actorType !== null && $actorId !== null) {
			$attendee = new Attendee();
			$attendee->setActorType($actorType);
			$attendee->setActorId($actorId);

			$participant = $this->createMock(Participant::class);
			$participant->method('getAttendee')->willReturn($attendee);

			$expectedActorType = $actorType;
			$expectedActorId = $actorId;
		} else {
			$participant = null;

			$expectedActorType = Attendee::ACTOR_USERS;
			$expectedActorId = 'logged_in_user';
		}

		$event = new ModifyRoomEvent($room, 'callRecording', $newStatus, $oldStatus, $participant);

		if ($expectedMessage !== null) {
			$this->chatManager->expects($this->once())
				->method('addSystemMessage')
				->with(
					$room,
					$expectedActorType,
					$expectedActorId,
					json_encode($expectedMessage),
					$this->dummyTime,
					false,
					self::DUMMY_REFERENCE_ID,
					null,
					false
				);
		} else {
			$this->chatManager->expects($this->never())
				->method('addSystemMessage');
		}

		$this->dispatch(Room::EVENT_AFTER_SET_CALL_RECORDING, $event);
	}
}
