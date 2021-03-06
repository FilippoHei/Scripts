function [txt ,star] = findKSsignificance(Group1,Group2)
p = [];
    p(1) = kstest2(Group1, Group2, 'Alpha', 0.05);
    for P = 2:100
        p((P)) = kstest2(Group1, Group2, 'Alpha', 10^(-P));
    end
    pInd = find(p == false);
    if pInd(1) == 1
        star = 'ns';
        txt= 'p = ns';
    elseif pInd(1) == 2
        star = '*';
        txt= [star, 'p < 0.05'];
    else
        star = '*';
        for a = 2:(pInd(1)-1)
            star = [star, '*'];
        end
        pTxt =  ['0.', num2str(zeros(1,(pInd(1)-2))), '1'];
        pTxt(pTxt == ' ') = [];
        txt = [star, 'p < ', pTxt];
    end
end
