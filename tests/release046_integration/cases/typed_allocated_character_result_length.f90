program p
implicit none
integer::i
character(:),allocatable::a,b,c
character(4)::words(2)
a='a'
b='bbbb'
c=min(a,b)
words=[character(4)::(c,i=1,2)]
print '(i0,a,a,a,a,a)',len(c),'[',words(1),'][',words(2),']'
end program
