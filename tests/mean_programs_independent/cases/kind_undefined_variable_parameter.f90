program p
implicit none
real(8)::zz
integer,parameter::kk=kind(zz)
real(kk)::aa(2)=[1.0_kk,2.0_kk]
print *,kk,aa
end program p
