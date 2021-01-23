function plotKPs(kps, img)
imshow(img); 
hold on;
kps = flipud(kps); 
plot((kps(2, :))', (kps(1, :))', 'go'); 
end

