program main
implicit none
character(2)::a(2,2)
a(:,1)=['ab','cd']
a(:,2)=['ef','gh']
print *,pack(a,a>'cd')
end program
