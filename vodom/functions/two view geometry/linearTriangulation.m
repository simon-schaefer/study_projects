function P = linearTriangulation(p1,p2,M1,M2)
% LINEARTRIANGULATION  Linear Triangulation
% @param[in]    p1(3,N): homogeneous coordinates of points in image 0.
% @param[in]    p2(3,N): homogeneous coordinates of points in image 1.
% @param[in]    M1(3,4): projection matrix corresponding to first image.
% @param[in]    M2(3,4): projection matrix corresponding to second image.
% @param[out]   P(4,N):  homogeneous coordinates of 3-D points.
num_points = size(p1,2); 
P = zeros(4,num_points);
% Linear algorithm.
for j=1:num_points
    % Build matrix of linear homogeneous system of equations.
    A1 = cross2Matrix(p1(:,j))*M1;
    A2 = cross2Matrix(p2(:,j))*M2;
    A = [A1; A2];
    % Solve the linear homogeneous system of equations.
    [~,~,v] = svd(A,0);
    P(:,j) = v(:,4);
end
% Dehomogeneize (P is expressed in homogeneous coordinates).
P = P./repmat(P(4,:),4,1); 
return


