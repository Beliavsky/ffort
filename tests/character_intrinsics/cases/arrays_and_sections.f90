program p
implicit none
character(5)::s(4)
s=['aba  ',' bab ','     ','xxyxx']
print *, index(s,'b'),index('banana',['a ','an','na','zz'])
print *, index(s,['a ','b ','  ','x '],[.false.,.true.,.true.,.true.],8)
print *, len_trim(s),len_trim(s(4:1:-1),kind=8)
print '(a)', '<'//adjustl(s(2:1:-1))//'>'
print '(a)', '<'//adjustr(s(1:2))//'>'
print *, index('aba','a',[.false.,.true.,.false.,.true.])
end program
