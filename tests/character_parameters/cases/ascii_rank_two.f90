implicit none
integer(8)::i(2,2)=reshape([65_8,66_8,67_8,68_8],[2,2])
print '(a)',achar(i),char(i,1)
end
