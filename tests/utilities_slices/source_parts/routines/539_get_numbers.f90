subroutine get_numbers(list, n)
!     Read in a list of numbers which may be separated by commas, blanks
!     or either `..' or `-'.
integer, intent(out) :: list(:) ! contains data read on output
integer, intent(out) :: n       ! # of values read
!     Local variables
character (len=4)   :: delimiters = " ,-."
character (len=100) :: text
integer             :: nmax, length, i1, i2, iostatus, i, number
logical             :: sequence
nmax = size(list)
start: do
  write (*,*) "enter variable numbers on one line"
  write (*,*) "e.g. 1-5 8 11 .. 15  use commas or blanks as separators"
  write (*,*) ": "
  read(*, "(a) ") text
  text = adjustl(text)
  length = len_trim(text)
  if (length == 0) then
    n = 0
    return
  end if
  n = 1
  i1 = 1
  sequence = .false.
  do
    i2 = scan( text(i1:), delimiters )
    if (i2 == 0) then
      i2 = length
    else
      i2 = i2 + i1 - 2
    end if
    read(text(i1:i2),*, iostat=iostatus) number
    if (iostatus /= 0) then
      write (*,*) "** error: numeric data expected **"
      write (*, "(1x, a) ") text(1:length)
      text = " "
      do i = i1, i2
        text(i:i) = "^"
      end do
      write (*, "(1x, a) ") text(1:i2)
      cycle start
    end if
    if (sequence) then
      if (number <= list(n-1)) then
        write (*,*) "variable numbers not increasing"
        write (*, "(1x, a) ") text(1:length)
        text = " "
        do i = i1, i2
          text(i:i) = "^"
        end do
        write (*, "(1x, a) ") text(1:i2)
        cycle start
      end if
      do
        if (n > size(list)) then
           n = size(list)
           exit
        end if
        list(n) = list(n-1) + 1
        if (list(n) >= number) exit
        n = n + 1
      end do
    else
      list(n) = number
    end if
    if (i2 == length) return
    i1 = i2 + 1
    sequence = .false.
                                       ! Find end of delimiters
    do
      if ( scan( text(i1:i1), delimiters ) > 0) then
        if (text(i1:i1) == "-" .or. text(i1:i1+1) == "..") sequence = .true.
        i1 = i1 + 1
      else
        exit
      end if
    end do
    n = n + 1
    if (n > nmax) then
      write (*,*) "** too many numbers entered - list truncated **"
      n = nmax
      return
    end if
  end do
end do start
return
end subroutine get_numbers
!
