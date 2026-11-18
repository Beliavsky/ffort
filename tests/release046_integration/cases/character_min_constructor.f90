program p
implicit none
integer::i
character(2)::pool(3),words(3)
pool=['b ','a ','c ']
i=9
words=[(min(pool(i),'bb'),i=1,3)]
print '(*(a))','[',words(1),'][',words(2),'][',words(3),']'
print '(i0)',i
end program
