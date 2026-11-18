program p
implicit none
integer::i
character(2)::pool(3)
character(4)::words(3),other(3)
pool=['b ','a ','z ']
words=[character(4)::(min(pool(i),'bb'),i=1,3)]
other=max(words,'c')
print '(*(a))','[',other(1),'][',other(2),'][',other(3),']'
end program
