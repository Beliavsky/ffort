program p
implicit none
integer::a(2),v(1)
a=1;v=2
print *,size(reshape(pack(a,.true.,vector=v),[0]))
end program
