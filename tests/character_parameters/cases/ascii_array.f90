implicit none
integer::i(3)=[65,66,67]
print '(a)',char(i),achar(i,1)
end
