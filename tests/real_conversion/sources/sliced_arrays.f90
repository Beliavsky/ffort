program p
implicit none
integer::i(5)=[1,2,3,4,5]
real(8)::a(3)
a=real(i(5:1:-2),8)
print *,a,real(i(2:4),kind=8)
print *,kind(real(i(5:1:-2),8)),sum(real(i(5:1:-2),8))
end program p
