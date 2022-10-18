// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

import "@openzeppelin-solidity/contracts/access/Ownable.sol";


contract Voting is Ownable {

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    event VoterRegistered(address voterAddress);
    event ProposalsRegistrationStarted();
    event ProposalsRegistrationEnded();
    event ProposalRegistered(uint proposalId);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted (address voter, uint proposalId);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);

    uint public winningProposalId;

    mapping(address => bool) public whitelist;
    mapping(address => Voter) public voters;
    mapping(uint => WorkflowStatus) private state;

    WorkflowStatus public votingStatus;
    Proposal[] public proposals;

    //Vérification de l'addresse si elle est enregistré ou non sur la liste blanche

    modifier registred {
        require(whitelist[msg.sender] == true, "Non enregistre sur la liste blanche");
        _;
    }

    //Permet a l'admin d'ajouter un élécteur à la liste blanche avec comme paramètre l'addresse du votant
     
    function addWhiteList(address voterAddress) external onlyOwner {
        require(!whitelist[voterAddress], "Vous etes deja enregistre");
        whitelist[voterAddress] = true;
        voters[voterAddress] = Voter(true, false, 0);
        emit VoterRegistered(voterAddress);
    }

    //Passez a l'étape de processus de session de vote

    function nextStep() external onlyOwner {
        votingStatus = WorkflowStatus(uint(votingStatus)+1);
        emit WorkflowStatusChange(WorkflowStatus(uint(votingStatus)-1), WorkflowStatus(uint(votingStatus)));
        if (votingStatus == WorkflowStatus(uint(1))) { startProposalsRegistration();}
        if (votingStatus == WorkflowStatus(uint(2))) { closeProposalsRegistration();}
        if (votingStatus == WorkflowStatus(uint(3))) { startVotingSession();}
        if (votingStatus == WorkflowStatus(uint(4))) { closeVotingSession();}
        if (votingStatus == WorkflowStatus(uint(5))) { getWinningProposal();}
    }

    //Démarrer la session de proposition de vote

    function startProposalsRegistration() private onlyOwner {
        addProposal("Abstention");
        emit ProposalsRegistrationStarted();

    }

    //Ajouter une description de la propostion

    function addProposal(string memory description) public registred {
        require(votingStatus == WorkflowStatus.ProposalsRegistrationStarted, "impossible de faire des propositions");
        proposals.push(Proposal(description,0));
        uint id = proposals.length;
        emit ProposalRegistered(id);
    }
       
    //Met fin aux enregistrements des propositions

    function closeProposalsRegistration() private onlyOwner {
        emit ProposalsRegistrationEnded();
    }

    //Commencement de la session de vote

    function startVotingSession() private onlyOwner {
        emit VotingSessionStarted();

    }

    //Voter pour une proposition de vote

    function addVote(uint _proposalId) external registred {
        require(votingStatus == WorkflowStatus.VotingSessionStarted, "impossible de voter");
        require(voters[msg.sender].hasVoted == false, "Vous avez deja voter :'(");
        proposals[_proposalId].voteCount++;
        voters[msg.sender] = Voter(true, true, _proposalId);
        emit Voted (msg.sender, _proposalId);
    }

    //Fin de la session de vote

    function closeVotingSession() private onlyOwner {
        emit VotingSessionEnded();
    }
    //Je n'ai réussi à faire la partie du décompte de vote.