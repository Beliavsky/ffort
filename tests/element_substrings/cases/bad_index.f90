implicit none
character(4)::x(2)=['abcd','efgh']
integer::i=3
print '(a)',x(i)(2:3)
end
