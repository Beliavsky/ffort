program main
implicit none
integer::i
character(4096)::a
a="x"
print '(4096a1)', (a,i=1,4096)
end program
