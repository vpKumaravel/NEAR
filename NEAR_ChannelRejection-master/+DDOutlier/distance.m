function [dist] = distance(DataSet,i,j,k)

    [kdist_obj,~] = DDOutlier.kDistObj(DataSet,k);
    
    [~,neighborLevel_j] = find(kdist_obj.id(i,:) == j);
    if ~isempty(neighborLevel_j)
        dist = kdist_obj.dist(i,neighborLevel_j); 
    else
        [~,neighborLevel_i] = find(kdist_obj.id(j,:) == i);
        if ~isempty(neighborLevel_i)
            dist = kdist_obj.dist(j,neighborLevel_i); 
        else
            error('an error occurred in distance.m');
        end
    end
    
end