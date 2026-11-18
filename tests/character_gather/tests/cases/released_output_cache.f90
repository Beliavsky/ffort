implicit none
character(65536)::x(1)
integer::i
x='a'
print '(i1)',(index(x([1]),'a'),i=1,257)
end
