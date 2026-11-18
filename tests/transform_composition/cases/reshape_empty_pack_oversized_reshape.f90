program p
implicit none
integer::sh(1)
sh=[1000001]
print *,size(pack(reshape([1],sh,pad=[1]),.false.))
end program
