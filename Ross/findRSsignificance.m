function [Txt ,star] = findSRsignificance(Group1,Group2)
p = [];
  [val, p(1)] = ranksum(Group1, Group2, 'Alpha', 0.05);
    for P = 2:40
       [val, p((P))] = ranksum(Group1, Group2, 'Alpha', 10^(-P));
    end
    pInd = find(p == false);
    if pInd(1) == 1
        star = 'ns';
        Txt= 'p = ns';
    elseif pInd(1) == 2
        star = '*';
        Txt= [star, 'p < 0.05'];
    else
        star = '*';
        for a = 2:(pInd(1)-1)
            star = [star, '*'];
        end
        pTxt =  ['0.', num2str(zeros(1,(pInd(1)-2))), '1'];
        pTxt(pTxt == ' ') = [];
        Txt = [star, 'p < ', pTxt];
    end
end
