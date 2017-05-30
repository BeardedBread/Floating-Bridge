classdef Player < handle
    properties (SetAccess = private)
        num %which player num are you?
        type
        hand        
        role
        partner
        points
        % Memory of AI player
        memory_bid
        memory_cards_played
        % Belief of AI
        belief_partner
        belief_carddist
        % AI specific variables
        w_a
        w_b
    end
    methods
        function pl = Player(type,num,cards)
            pl.num=num;
            pl.type=type;
            if strcmp(pl.type,'Vibot1')
                A=load('Vibot1.mat');
                pl.w_a=A.w_a;
                pl.w_b=A.w_b;
            end
            pl.hand=cards;
            pl.points=0;
            pl.role='No Role Yet';
            pl.partner=0;
            pl.memory_bid=zeros(7,4);
            pl.memory_cards_played=repmat([Cards(1,1,1) Cards(1,1,1) Cards(1,1,1) Cards(1,1,1)],13,1);
            pl.belief_partner=zeros(1,4);
            pl.belief_carddist=zeros(4,13,4);
        end
        
        function update_Hand(pl,hand)
            pl.hand=hand;
        end
        
        function determine_Point(player)
            cards_value = [player.hand.value];
            cards_suits = floor(cards_value/100);
            cards_num = mod(cards_value,100);
            points_jqka = zeros(1,4);
            for i=1:4
                points_jqka(i)=sum(cards_num==10+i)*i;
            end
            no_of_cards_in_each_suit = zeros(1,4);
            for n=1:4
                no_of_cards_in_each_suit(n)=sum(cards_suits==n);
            end
            five_of_a_kind=sum(no_of_cards_in_each_suit>=5);
            player.points=sum(points_jqka)+five_of_a_kind;
        end
        
        function request_reshuffle=check_Points(player,message_text,choice_button,win)
            if player.points<4
                switch player.type
                    case 'randomAI'
                        request_reshuffle=AI.getAction(player,0);
                    case 'Human'
                        set(message_text,'string','Do you want to request for reshuffle?');
                        set(choice_button(1),'visible','on');set(choice_button(2),'visible','on');
                        uiwait(win);
                        request_reshuffle=win.UserData.decision;
                    case 'Vibot1'
                        request_reshuffle=Vibot1.getAction(player,0);
                    otherwise
                        disp('Player type not valid')
                end
            else
                request_reshuffle=0;
            end
            if request_reshuffle==1
                set(message_text,'string',['Player ',num2str(player.num),' requested for reshuffle']);
            end
        end
        
        function bid=place_Bid(player,current_bid,pl_bid,win,bidsuit_button,...
                bidnum_button,display_bidnum,display_bidsuit,bid_button,pass_button)
            switch player.type
                case 'randomAI'
                    bid=AI.getAction(player,1,current_bid,0.3);
                case 'Human'
                    set(bidsuit_button,'visible','on');set(bidnum_button,'visible','on');
                    set(bid_button,'visible','on');set(pass_button,'visible','on');
                    set(display_bidnum,'visible','on');set(display_bidsuit,'visible','on');
                    bid=Human.bet(current_bid,pl_bid,win);
                case 'Vibot1'
                    bid=Vibot1.getAction(player,1,current_bid,0.3);
                otherwise
                    disp('Player type not valid')
            end
            player.memory_bid=pl_bid;
        end
        
        function name_Declarer(player)
            player.role='Declarer';
        end
        
        function card_selected=choose_Partner(player,all_cards,table,win,message_text,partner_button,...
                call_button,bidsuit_button,display_bidnum,display_bidsuit)
            switch player.type
                case 'randomAI'
                    card_selected=AI.getAction(player,2,table.trump_suit,all_cards);
                case 'Human'
                    set(bidsuit_button(1:4),'visible','on');
                    set(display_bidnum,'string',''); set(display_bidsuit,'string','');
                    set(display_bidnum,'visible','on'); set(display_bidsuit,'visible','on');
                    set(partner_button,'visible','on');set(call_button,'visible','on');
                    set(message_text,'string','Choose your partner');
                    card_selected=Human.partner(player,all_cards,win,message_text);
                case 'Vibot1'
                    card_selected=Vibot1.getAction(player,2,table.trump_suit,all_cards);
                otherwise
                    disp('Player type not valid')
            end
        end
        
        function identify_Role(player,partner_card,declarer)
            got_card=[player.hand.value]==partner_card.value;
            if got_card ==0
                player.role='Defender';
            else
                player.role='Partner';
                player.partner=declarer;
            end
        end
        
        function [card_played,selected_card_ind]=play_Card(player, round,tb,win,player_hand_deck)
            switch player.type
                case 'randomAI'
                    card_played=AI.getAction(player, 3,round.leading_suit,tb);
                case 'Human'
                    card_played=Human.select_Card(player, round.leading_suit,tb,win,player_hand_deck);
                case 'Vibot1'
                    card_played=Vibot1.getAction(player,3,round.leading_suit,tb);
                otherwise
                    disp('Player type not valid')
            end            
            selected_card_ind=find([player.hand.value]==card_played.value);
            % update hand of player by removing the played card
            index=find([player.hand.value]~=card_played.value);
            player.hand=player.hand(index);
        end
        
        function update_Players_Partners(pl,partner,defenders)
            switch pl.role
                case 'Declarer'
                    pl.partner=partner;
                case 'Defender'
                    pl.partner=find(defenders~=pl.num);
                otherwise
                    input('You are suppose to know your partner!')
            end
        end
        
        function update_Memory(player, round)
            player.memory_cards_played(round.trick_no,:)=round.cards_played;
        end
    end
end