implicit none
character(4)::x(2)=['abcd','efgh']
integer::j=5
print '(a)',x(1)(2:j)
end
