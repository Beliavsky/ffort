function c(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10) result(vec)
! return character array containing present arguments
character (len=*)  , intent(in), optional    :: x1,x2,x3,x4,x5,x6,x7,x8,x9,x10
character (len=100)            , allocatable :: vec(:)
character (len=100)            , allocatable :: vec_(:)
integer                                      :: n
allocate (vec_(10))
if (present(x1))  vec_(1)  = x1
if (present(x2))  vec_(2)  = x2
if (present(x3))  vec_(3)  = x3
if (present(x4))  vec_(4)  = x4
if (present(x5))  vec_(5)  = x5
if (present(x6))  vec_(6)  = x6
if (present(x7))  vec_(7)  = x7
if (present(x8))  vec_(8)  = x8
if (present(x9))  vec_(9)  = x9
if (present(x10)) vec_(10) = x10
n = count([present(x1),present(x2),present(x3),present(x4),present(x5), &
           present(x6),present(x7),present(x8),present(x9),present(x10)])
! print*,"n=",n !! debug
allocate (vec(n))
if (n > 0) vec = vec_(:n)
end function c
!
