implicit none
character(65536)::x(1)
integer::i,y(257)
x='a'
y=[(index(x([1]),'a'),i=1,257)]
print *,sum(y)
end
