// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

contract Ebay {
    struct Auction {
        uint256 id;
        address payable seller;
        string auctionName;
        string description;
        uint256 minimumPrice;
        uint256 endDate;
        uint256 bestOfferId;
        uint256[] offerIds;
    }

    struct Offer {
        uint256 id;
        uint256 auctionId;
        address payable buyer;
        uint256 price;
    }

    mapping(uint256 => Auction) private auctions;
    mapping(uint256 => Offer) private offers;
    mapping(address => uint256[]) private userAuctions;
    mapping(address => uint256[]) private userOffers;
    uint256 private nextAuctionId = 1;
    uint256 private nextOfferId = 1;

    function createAuction(
        string calldata _name,
        string calldata _description,
        uint256 _minimumPrice,
        uint256 _duration
    ) external {
        require(_minimumPrice > 0, "Price must be > 0");
        require(
            _duration > 86400 && _duration < 864000,
            "Duration last within 1 to 10 days"
        );
        // Define empty array
        uint256[] memory offerIds = new uint256[](0);
        auctions[nextAuctionId] = Auction(
            nextAuctionId,
            payable(msg.sender),
            _name,
            _description,
            _minimumPrice,
            block.timestamp + _duration,
            0,
            offerIds
        );
        userAuctions[msg.sender].push(nextAuctionId);
        nextAuctionId++;
    }

    function createOffer(uint256 _auctionId)
        external
        payable
        auctionExists(_auctionId)
    {
        // Pointer for auction
        Auction storage auction = auctions[_auctionId];
        // Pointer for offer
        Offer storage bestOffer = offers[auction.bestOfferId];
        require(block.timestamp < auction.endDate, "Auction expired");
        require(
            msg.value >= auction.minimumPrice && msg.value > bestOffer.price,
            "Offer must >= to minimumPrice and > the best offer"
        );
        auction.bestOfferId = nextOfferId;
        auction.offerIds.push(nextOfferId);
        offers[nextOfferId] = Offer(
            nextOfferId,
            nextAuctionId,
            payable(msg.sender),
            msg.value
        );
        userOffers[msg.sender].push(nextOfferId);
        nextOfferId++;
    }

    function trade(uint256 _auctionId) external auctionExists(_auctionId) {
        // Pointer for auction
        Auction storage auction = auctions[_auctionId];
        // Pointer for offer
        Offer storage bestOffer = offers[auction.bestOfferId];
        require(block.timestamp > auction.endDate, "Auction still active");
        for (uint256 i = 0; i < auction.offerIds.length; i++) {
            uint256 offerId = auction.offerIds[i];
            if (offerId != auction.bestOfferId) {
                Offer storage offer = offers[offerId];
                offer.buyer.transfer(offer.price);
            }
        }
        auction.seller.transfer(bestOffer.price);
    }

    function getAuctions() external view returns (Auction[] memory) {
        Auction[] memory _auctions = new Auction[](nextAuctionId - 1);
        for (uint256 i = 1; i < nextAuctionId + 1; i++) {
            _auctions[i - 1] = auctions[i];
        }
        return _auctions;
    }

    function getUserAuctions(address _user)
        external
        view
        returns (Auction[] memory)
    {
        uint256[] storage userAuctionIds = userAuctions[_user];
        Auction[] memory _auctions = new Auction[](userAuctionIds.length);
        for (uint256 i = 0; i < userAuctionIds.length; i++) {
            uint256 auctionId = userAuctionIds[i];
            _auctions[i] = auctions[auctionId];
        }
        return _auctions;
    }

    function getUserOffers(address _user)
        external
        view
        returns (Offer[] memory)
    {
        uint256[] storage userOfferIds = userOffers[_user];
        Offer[] memory _offers = new Offer[](userOfferIds.length);
        for (uint256 i = 0; i < userOfferIds.length; i++) {
            uint256 offerId = userOfferIds[i];
            _offers[i] = offers[offerId];
        }
        return _offers;
    }

    modifier auctionExists(uint256 _auctionId) {
        require(
            _auctionId > 0 && _auctionId < nextAuctionId,
            "Auction does not exist"
        );
        _;
    }
}
