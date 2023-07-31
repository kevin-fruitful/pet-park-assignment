//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract PetPark {
    /// FIRST THING FIRST ///

    constructor() payable {
        owner = msg.sender;
    }

    /// TYPES ///

    enum AnimalType {
        None,
        Fish,
        Cat,
        Dog,
        Rabbit,
        Parrot
    }

    enum Gender {
        None,
        Male,
        Female
    }

    struct Borrower {
        AnimalType animalType;
        uint128 age;
        Gender gender;
    }

    /// EVENTS ///

    event Added(AnimalType animalType, uint256 count);
    event Borrowed(AnimalType animalType);
    event Returned(AnimalType animalType);

    /// ERRORS ///

    error OnlyOwner(address owner, address caller);
    error CannotBorrowWhenAgeZero();

    /// MODIFIERS ///

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner(owner, msg.sender);
        _;
    }

    /// STORAGE ///

    address public owner;
    mapping(AnimalType => uint256 animalCount) public animalCounts;
    mapping(address borrowerAddress => Borrower borrowerInfo) public borrowers;

    /// FUNCTIONS ///

    /// @dev Add animals to the park.
    /// @param animalType Animal to be added.
    /// @param count Number of animals to be added.
    function add(AnimalType animalType, uint256 count) external onlyOwner {
        require(animalType != AnimalType.None, "Invalid animal");

        animalCounts[animalType] += count;

        emit Added(animalType, count);
    }

    /// @dev Borrow an animal from the park.
    /// @param age Age of the borrower. Sets the age if the borrower (msg.sender) is borrowing for the first time.
    /// @param gender Gender of the borrower. Sets the gender of the borrower (msg.sender) if borrowing for the first
    /// time.
    /// @param animalType Type of animal to borrow.
    function borrow(uint128 age, Gender gender, AnimalType animalType) external {
        // Validate animal type and availability
        require(animalType != AnimalType.None, "Invalid animal type");
        require(animalCounts[animalType] > 0, "Selected animal not available");

        // Validate age, and store age if new borrower
        if (age == 0) revert CannotBorrowWhenAgeZero();

        if (borrowers[msg.sender].age == 0) {
            borrowers[msg.sender].age = age;
        } else {
            require(borrowers[msg.sender].age == age, "Invalid Age");
        }

        // Validate gender, and store gender if new borrower
        if (borrowers[msg.sender].gender == Gender.None) {
            borrowers[msg.sender].gender = gender;
        } else {
            require(borrowers[msg.sender].gender == gender, "Invalid Gender");
        }

        // Ensure borrower is not currently borrowing an animal
        require(borrowers[msg.sender].animalType == AnimalType.None, "Already adopted a pet");

        // Check borrowing rules for Males
        if (gender == Gender.Male) {
            require(animalType == AnimalType.Dog || animalType == AnimalType.Fish, "Invalid animal for men");
        }

        // Check borrowing rules for Females
        if (age < 40 && gender == Gender.Female && animalType == AnimalType.Cat) {
            revert("Invalid animal for women under 40");
        }

        // Assign the animal to the borrower and decrement the animal count
        borrowers[msg.sender].animalType = animalType;
        unchecked {
            --animalCounts[animalType];
        }

        emit Borrowed(animalType);
    }

    /// @dev Return an animal to the park.
    function giveBackAnimal() external {
        require(borrowers[msg.sender].animalType != AnimalType.None, "No borrowed pets");

        AnimalType animalType = borrowers[msg.sender].animalType;
        borrowers[msg.sender].animalType = AnimalType.None;
        unchecked {
            ++animalCounts[animalType];
        }

        emit Returned(animalType);
    }
}
