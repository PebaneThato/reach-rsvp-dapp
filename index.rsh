'reach 0.1';

const [isHand, ROCK, PAPER, SCISSORS] = makeEnum(3);
const [isOutcome, B_WINS, DRAW, A_WINS] = makeEnum(3);

const winner = (handAlice, handBob) =>
  ((handAlice + (4 - handBob)) % 3);

assert(winner(ROCK, PAPER) == B_WINS);
assert(winner(PAPER, ROCK) == A_WINS);
assert(winner(ROCK, ROCK) == DRAW);

forall(UInt, handAlice =>
  forall(UInt, handBob =>
    assert(isOutcome(winner(handAlice, handBob)))));

forall(UInt, (hand) =>
  assert(winner(hand, hand) == DRAW));

const Player = {
  ...hasRandom,
  seeOutcome: Fun([UInt], Null),
  informTimeout: Fun([], Null),
};

export const main = Reach.App(() => {
  const Alice = Participant('Alice', {
    ...Player,
    wager: UInt, // atomic units of currency
    deadline: UInt, // time delta (blocks/rounds)
    approveInvitee: Fun([], UInt),
  });
  const Bob = Participant('Bob', {
    ...Player,
    acceptWager: Fun([UInt], Null),
    requestRefund: Fun([], UInt),
  });
  init();

  const informTimeout = () => {
    each([Alice, Bob], () => {
      interact.informTimeout();
    });
  };

  Alice.only(() => {
    const wager = declassify(interact.wager);
    const deadline = declassify(interact.deadline);
  });
  Alice.publish(wager, deadline)
    .pay(wager);
  commit();

  Bob.only(() => {
    interact.acceptWager(wager);
  });
  Bob.pay(wager)
    .timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout));

  var outcome = DRAW;
  invariant(balance() == 2 * wager && isOutcome(outcome));
  while (outcome == DRAW) {
    commit();

    Alice.only(() => {
      const _handAlice = interact.approveInvitee();
      const approvalStatus = declassify(_handAlice);
      const [_commitAlice, _saltAlice] = makeCommitment(interact, _handAlice);
      const commitAlice = declassify(_commitAlice);
    });
    Alice.publish(approvalStatus, commitAlice)
      .timeout(relativeTime(deadline), () => closeTo(Bob, informTimeout));

    if (approvalStatus === B_WINS) {
      commit();
      Alice.pay(2 * wager)
        .timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout));
      transfer(2 * wager).to(Bob);
      outcome = B_WINS;
      continue;
    }

    if (approvalStatus === A_WINS) {
      commit();
      Bob.pay(2 * wager)
        .timeout(relativeTime(deadline), () => closeTo(Bob, informTimeout));
      transfer(2 * wager).to(Alice);
      outcome = A_WINS;
      continue;
    }

    continue;
  }

  assert(outcome == A_WINS || outcome == B_WINS);
  transfer(2 * wager).to(outcome == A_WINS ? Alice : Bob);
  commit();

  each([Alice, Bob], () => {
    interact.seeOutcome(outcome);
  });
});
