program p
implicit none
character(8)::s='ab ab ab'
character(3)::x(3)
integer::i
forall(i=1:3) x(i)=adjustl(s(3*i-2:3*i-1))
print '(3a)',x
print *,index(x,'b'),index(x,'a'),len_trim(x)
s(2:5)=adjustr(s(1:4))
print '(a)',s
end program
