# Sector Stack | ElvaBoot i686

When a procedure needs to read a sector, it requests the sector reader
to increase the sector stack size  by one entry and read the sector to
that buffer.

That is done because otherwise, if all  procedures use the same sector
buffer, a procedure  which needs a sector could call another procedure
which uses  the same buffer  and overwrites  the data. If  that called
procedure then returns, the caller malfunctions because of wrong data.

A stack of  sectors is an elegant solution  for not having to define a
different buffer  address for each functions that  reads from the disk
while still  having the  safety. Now, every function  reading from the
disk only needs to `pop` its own sector from the stack on return.

