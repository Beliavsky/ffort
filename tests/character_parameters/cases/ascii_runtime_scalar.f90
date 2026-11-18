implicit none
integer::i=65
integer(8)::j=90
print '(a)',char(i),achar(j),char(i,1),achar(j,kind=1)
end
