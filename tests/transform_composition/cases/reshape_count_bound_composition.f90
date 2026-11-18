program p
implicit none
integer::a(2,2)
logical::mask(2,2)
a=reshape([1,2,3,4],[2,2],order=[2,1])
mask=a>2
print *,count(reshape(pack(mask,.true.),[2,2]),dim=1,kind=8)
print *,lbound(reshape(pack(a,.true.),[2,2]),1),lbound(reshape(pack(a,.true.),[2,2]),2), &
ubound(reshape(pack(a,.true.),[2,2]),1),ubound(reshape(pack(a,.true.),[2,2]),2)
end program
