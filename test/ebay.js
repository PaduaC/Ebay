const {
  expectRevert,
  expectEvent,
  time,
} = require("@openzeppelin/test-helpers");
const { web3 } = require("@openzeppelin/test-helpers/src/setup");
const Ebay = artifacts.require("Ebay");

contract("Ebay", (accounts) => {
  let ebay;
  const auction = {
    name: "Chintendo Vii",
    description: "250 games in 1 can play Super Mari and Sinoc",
    min: 10,
    duration: 86400 + 1,
  };
  const [seller, buyer1, buyer2] = [accounts[0], accounts[1], accounts[2]];
  beforeEach(async () => {
    ebay = await Ebay.new();
  });

  it("should NOT create a new auction if duration is not between 1-10 days", async () => {
    await expectRevert(
      ebay.createAuction(auction.name, auction.description, auction.min, 800),
      "Duration must last within 1 to 10 days"
    );
  });

  it("should create an auction", async () => {
    const tx = await ebay.createAuction(
      auction.name,
      auction.description,
      auction.min,
      auction.duration
    );
    await expectEvent(tx, "AuctionCreated", {
      name: auction.name,
      description: auction.description,
      minPrice: web3.utils.toBN(auction.min),
      duration: web3.utils.toBN(auction.duration),
    });
  });

  it("should NOT create offer if auction does not exist", async () => {
    await expectRevert(
      ebay.createOffer(web3.utils.toBN(4)),
      "Auction does not exist"
    );
  });

  it("should NOT create offer if auction has expired", async () => {
    await ebay.createAuction(
      auction.name,
      auction.description,
      auction.min,
      auction.duration
    );
    time.increase(864000);
    await expectRevert(ebay.createOffer(web3.utils.toBN(1)), "Auction expired");
  });

  it("should NOT create offer if price too low", async () => {
    await ebay.createAuction(
      auction.name,
      auction.description,
      auction.min,
      auction.duration
    );
    await expectRevert(
      ebay.createOffer(web3.utils.toBN(1), { value: 2 }),
      "Offer must >= to minimumPrice and > the best offer"
    );
  });

  it("should create offer", async () => {
    const tx = await ebay.createAuction(
      auction.name,
      auction.description,
      auction.min,
      auction.duration
    );
    const price = web3.utils.toBN(20);
    const offer = await ebay.createOffer(web3.utils.toBN(1), {
      from: buyer1,
      value: price,
    });
    await expectEvent(tx, "AuctionCreated", {
      name: auction.name,
      description: auction.description,
      minPrice: web3.utils.toBN(auction.min),
      duration: web3.utils.toBN(auction.duration),
    });
    await expectEvent(offer, "NewOffer", {
      auctionId: web3.utils.toBN(1),
      buyer: buyer1,
      price: "20",
    });
  });

  it("should NOT trade if auction does not exist", async () => {
    await expectRevert(
      ebay.trade(web3.utils.toBN(4)),
      "Auction does not exist"
    );
  });

  it("should trade", async () => {
    const tx = await ebay.createAuction(
      auction.name,
      auction.description,
      auction.min,
      auction.duration
    );
    const offer1 = await ebay.createOffer(web3.utils.toBN(1), {
      from: buyer1,
      value: web3.utils.toBN(20),
    });
    const offer2 = await ebay.createOffer(web3.utils.toBN(1), {
      from: buyer2,
      value: web3.utils.toBN(30),
    });
    const duration = time.increase(86402);
    const trade = await ebay.trade(web3.utils.toBN(1), { from: seller });

    await expectEvent(tx, "AuctionCreated", {
      name: auction.name,
      description: auction.description,
      minPrice: web3.utils.toBN(auction.min),
      duration: web3.utils.toBN(auction.duration),
    });
    await expectEvent(offer1, "NewOffer", {
      auctionId: web3.utils.toBN(1),
      buyer: buyer1,
      price: "20",
    });
    await expectEvent(offer2, "NewOffer", {
      auctionId: web3.utils.toBN(1),
      buyer: buyer2,
      price: "30",
    });
    await expectEvent(trade, "AuctionEnded", {
      name: auction.name,
      description: auction.description,
      price: web3.utils.toBN(auction.min),
    });
  });
});
