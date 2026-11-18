program p
implicit none
integer::i
i=99
print '(*(b4.4))',[(i,i=0,3)]
print '(i0)',i
end program
