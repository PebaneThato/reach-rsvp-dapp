'reach 0.1';

const [ isAction, APRROVE, WAIT, DECLINE ] = makeEnum(3);
const [ isOutcome, YES, DRAW, NO ] = makeEnum(3);

const outcomeAction = (OrganizerAction, ClientAction) =>
  ((OrganizerAction + (4 - ClientAction)) % 3);

assert(outcomeAction(APRROVE, WAIT) == YES);
assert(outcomeAction(WAIT, APRROVE) == NO);
assert(outcomeAction(APRROVE, APRROVE) == DRAW);

forall(UInt, OrganizerAction =>
  forall(UInt, ClientAction =>
    assert(isOutcome(outcomeAction(OrganizerAction, ClientAction)))));

forall(UInt, (action) =>
  assert(outcomeAction(action, action) == DRAW));

const User = {
  ...hasRandom,
  seeOutcome: Fun([UInt], Null),
  informTimeout: Fun([], Null),
};

export const main = Reach.App(() => {
  const Organizer = Participant('Organizer', {
    ...User,
    product: Object({premium: UInt, cover: UInt}), // atomic units of currency
    deadline: UInt, // time delta (blocks/rounds),
    activateCover: Fun([], UInt),
    approveOrDeclineClaim: Fun([], UInt),
  });
  const Client = Participant('Client', {
    ...User,
    acceptAndBuyProduct: Fun([UInt, UInt], Null),
    claim: Fun([], UInt),
  });
  deploy();

  const informTimeout = () => {
    each([Organizer, Client], () => {
      interact.informTimeout();
    });
  };

  Organizer.only(() => {
    const {premium, cover} = declassify(interact.product);
    const deadline = declassify(interact.deadline);
  });
  Organizer.publish(premium, cover, deadline)
    .pay(cover);
  commit();

  Client.only(() => {
    interact.acceptAndBuyProduct(premium, cover);
  });
  Client.pay(premium)
    .timeout(relativeTime(deadline), () => closeTo(Organizer, informTimeout));
  transfer(premium).to(Organizer);

  var outcome = DRAW;
  invariant( balance() == cover && isOutcome(outcome) );
  while ( outcome == DRAW ) {
    commit();

    Organizer.only(() => {
      const _isCoverActivated = interact.activateCover();
      const isCoverActivated = declassify(_isCoverActivated);
      const [_commitAlice, _saltAlice] = makeCommitment(interact, _isCoverActivated);
      const commitAlice = declassify(_commitAlice);
    });
    Organizer.publish(isCoverActivated, commitAlice)
      .timeout(relativeTime(deadline), () => closeTo(Client, informTimeout));
    if(isCoverActivated === DRAW){
      outcome = DRAW;
      continue;
    }
    if(isCoverActivated === NO){
        commit();
        Organizer.pay(premium)
          .timeout(relativeTime(deadline), () => closeTo(Organizer, informTimeout));
        transfer(premium).to(Client);
        outcome = NO;
        continue;
    }
    commit();

    Client.only(() => {
      const isClaimed = declassify(interact.claim());
    });
    Client.publish(isClaimed)
      .timeout(relativeTime(deadline), () => closeTo(Organizer, informTimeout));
    commit();

    Organizer.only(() => {
      const isClaimApproved = declassify(interact.approveOrDeclineClaim());
    });

    Organizer.publish(isClaimApproved)
      .timeout(relativeTime(deadline), () => closeTo(Client, informTimeout));

    outcome = outcomeAction(isClaimApproved, isClaimed);
    continue;
  }

  assert(outcome == NO || outcome == YES);
  transfer(cover).to(outcome == NO ? Organizer : Client);
  commit();

  each([Organizer, Client], () => {
    interact.seeOutcome(outcome);
  });
});